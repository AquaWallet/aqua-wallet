import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
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

    final filteredUtxos = await ref.read(liquidProvider).getUnspentOutputs();
    final transaction = GdkNewTransaction(
      addressees: [addressee],
      feeRate: fee ?? await network.getDefaultFees(),
      utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
      memo: sendInput.note,
      utxos: filteredUtxos?.unsentOutputs,
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
