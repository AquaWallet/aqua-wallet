import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/address_validator/address_validation.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';
import 'package:flutter/foundation.dart';

// Still a very early implementation, but the idea is for this to become the
// main transaction executor for send flows.
//
// The sole job of the executor is to create, sign, and broadcast raw BTC/LBTC
// transactions for send flow.
//
// It will be implemented by any other services we integrate in the future,
// such as (GDK, LWK, BWK, etc.).

final sendTransactionExecutorProvider =
    Provider.family<Transactor, SendAssetArguments>(SendGdkTransactor.new);

abstract class Transactor {
  Future<SendAssetOnchainTx> createTransaction({
    required SendAssetInputState sendInput,
    bool rbfEnabled = true,
  });

  Future<GdkNewTransactionReply> signTransaction({
    required GdkNewTransactionReply transaction,
    required NetworkType network,
  });

  Future<String> broadcastTransaction({
    required String rawTx,
    NetworkType network = NetworkType.liquid,
    bool useAquaNode = false,
  });
}

class SendGdkTransactor extends Transactor {
  SendGdkTransactor(this.ref, this.arg);

  final ProviderRef ref;
  final SendAssetArguments arg;

  @override
  Future<SendAssetOnchainTx> createTransaction({
    required SendAssetInputState sendInput,
    bool rbfEnabled = true,
  }) async {
    final network =
        ref.read(arg.asset.isBTC ? bitcoinProvider : liquidProvider);

    final feeValue = sendInput.fee?.when(
      bitcoin: (model) => model.feeSats,
      liquid: (fee) => fee.map(
        lbtc: (f) => f.feeSats,
        usdt: (f) => f.feeAmount,
      ),
    );

    // all non-btc assets are liquid assets
    final fee = !sendInput.asset.isBTC
        ? (ref.read(feeEstimateProvider).getLiquidFeeRate() * kVbPerKb).toInt()
        : feeValue;

    final String? address;
    if (!sendInput.asset.isAltUsdt) {
      address = sendInput.addressFieldText;
    } else {
      final swapPair = SwapPair(
        from: SwapAssetExt.usdtLiquid,
        to: SwapAsset.fromAsset(sendInput.asset),
      );
      final swapArgs = SwapArgs(pair: swapPair);
      final swapOrderState = ref.read(swapOrderProvider(swapArgs));
      address = swapOrderState.value?.order?.depositAddress;
    }

    // Could only happen with alt USDt
    if (address == null || address.isEmpty) {
      throw AddressParsingException(AddressParsingExceptionType.emptyAddress);
    }

    final addressee = GdkAddressee(
      address: address,
      satoshi: sendInput.amount,
      assetId: sendInput.sendAssetId,
      isGreedy: sendInput.isSendAllFunds,
    );

    final utxos = await _getUtxos(
      asset: sendInput.asset,
      transactionType: sendInput.transactionType,
      privateKey: sendInput.externalSweepPrivKey,
    );

    final transaction = GdkNewTransaction(
      addressees: [addressee],
      feeRate: fee ?? await network.getDefaultFees(),
      utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
      memo: sendInput.note,
      utxos: utxos?.unsentOutputs,
    );

    logger.debug('[Send] provider tx: $transaction');

    if (kDebugMode && fee != null && fee > sendInput.amount) {
      // Dev's idiotproofing for his future self
      // https://tenor.com/bxAO8.gif
      throw Exception('Fee is higher than the transaction amount');
    }

    final gdkNewTxReply = await network.createTransaction(
      transaction: transaction,
      rbfEnabled: rbfEnabled,
    );

    if (gdkNewTxReply == null) {
      throw GdkNetworkException('Failed to create GDK transaction');
    }

    return SendAssetOnchainTx.gdkTx(gdkNewTxReply);
  }

  Future<GdkUnspentOutputsReply?> _getUtxos({
    required Asset asset,
    required SendTransactionType transactionType,
    String? privateKey,
  }) async {
    final utxoFetcher = UtxoFetcher(ref);

    //for gdk, this function will fetch utxos available for that private key and will take care of the signing.
    //NOTE: this sweeping flow will probably have to change for lwk/bdk
    if (transactionType == SendTransactionType.privateKeySweep) {
      return utxoFetcher.getUtxosForPrivateKeySweep(privateKey, asset);
    }

    return asset.isLiquid ? utxoFetcher.getLiquidUtxos() : null;
  }

  @override
  Future<GdkNewTransactionReply> signTransaction({
    required GdkNewTransactionReply transaction,
    required NetworkType network,
  }) async {
    try {
      final provider = network == NetworkType.bitcoin
          ? ref.read(bitcoinProvider)
          : ref.read(liquidProvider);
      final signedTx = await provider.signTransaction(transaction);

      if (signedTx == null) {
        throw GdkNetworkException('Failed to sign GDK transaction');
      }
      return signedTx;
    } catch (e) {
      logger.debug('[SEND] sign gdk tx - error: $e');
      rethrow;
    }
  }

  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    NetworkType network = NetworkType.liquid,
    bool useAquaNode = false,
  }) async {
    final txHash = await ref
        .read(electrsProvider)
        .broadcast(rawTx, network, useAquaNode: useAquaNode);

    logger.info('[SEND] broadcast gdk tx - tx hash: $txHash');

    return txHash;
  }
}

class UtxoFetcher {
  final ProviderRef ref;

  UtxoFetcher(this.ref);

  // TODO: This function is not working. There is a strange error coming from GDK:
  //   "error" -> "the handshake failed: Interrupted system call (os error 4)"
  // Either we fix this or switch to BDK when ready.
  // Leaving in because the rest of the Bitcoin Chip Sweep flow is working.
  Future<GdkUnspentOutputsReply?> getUtxosForPrivateKeySweep(
      String? privateKey, Asset asset) async {
    if (privateKey == null || privateKey.isEmpty) {
      throw ArgumentError(
          'Private key must be provided for private key sweep transactions.');
    }

    final provider =
        asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

    // NOTE: GDK's getUnspentOutputsForPrivateKey() requires us to prefix the private key with "p2wpkh:"/"p2wpkh-p2sh:"
    // if we want to sweep native segwit or nested segwit addresses respectively.
    // Bitcoin Chip addresses are native segwit addresses, so hardcode to 'p2wpkh' here.
    // However, a more robust solution can be implemented when we switch to BDK
    return await provider.getUnspentOutputsForPrivateKey(
      privateKey,
      outputType: 'p2wpkh', // For bc1 addresses (native SegWit)
    );
  }

  Future<GdkUnspentOutputsReply?> getLiquidUtxos() async {
    return await ref.read(liquidProvider).getUnspentOutputs();
  }
}
