import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
import 'package:aqua/features/wallet/models/subaccount_exceptions.dart';
import 'package:aqua/features/wallet/providers/subaccounts_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/wallet/utils/derivation_path_utils.dart';
import 'package:aqua/logger.dart';

//TODO: This provider's usage is a one-off and we should show a flag when successfully swept. -OR- we can query number of txs in legacy vs native segwit to tell if legacy has been swept.

final liquidNativeSegwitSweepProvider =
    AsyncNotifierProvider<LiquidNativeSegwitSweepNotifier, void>(() {
  return LiquidNativeSegwitSweepNotifier();
});

class LiquidNativeSegwitSweepNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sweepLegacyToNativeSegwit() async {
    state = const AsyncLoading();

    try {
      final subaccountsNotifier = ref.read(subaccountsProvider.notifier);
      final liquid = ref.read(liquidProvider);

      // Find or create BIP84 native segwit liquid subaccount
      Subaccount? nativeSegwitSubaccount = _findNativeSegwitLiquidSubaccount();
      if (nativeSegwitSubaccount == null) {
        logger
            .debug('[subaccount] Creating new native segwit liquid subaccount');
        await subaccountsNotifier.createAccountSubaccount(
          networkType: NetworkType.liquid,
          type: GdkSubaccountTypeEnum.type_p2wpkh,
        );
        nativeSegwitSubaccount = _findNativeSegwitLiquidSubaccount();
      }

      if (nativeSegwitSubaccount == null) {
        throw NativeSegwitSubaccountCreationException();
      }
      logger.debug(
          '[subaccount] Native segwit subaccount pointer: ${nativeSegwitSubaccount.subaccount.pointer.toString()}');

      // Find legacy segwit liquid subaccount
      final legacySegwitSubaccount = _findLegacySegwitLiquidSubaccount();
      if (legacySegwitSubaccount == null) {
        throw LegacySegwitSubaccountNotFoundException();
      }
      logger.debug(
          '[subaccount] Legacy segwit subaccount pointer: ${legacySegwitSubaccount.subaccount.pointer.toString()}');

      // Get receive address for native segwit subaccount
      final receiveAddressDetails = await liquid.getReceiveAddress(
        details: GdkReceiveAddressDetails(
            subaccount: nativeSegwitSubaccount.subaccount.pointer),
      );

      if (receiveAddressDetails == null ||
          receiveAddressDetails.address == null) {
        throw ReceiveAddressException();
      }
      logger.info(
          '[subaccount] Receive address: ${receiveAddressDetails.address}');

      // Create and send transaction
      final transaction = await _createSweepTransaction(
        legacySegwitSubaccount: legacySegwitSubaccount,
        receiveAddress: receiveAddressDetails.address!,
      );

      if (transaction == null) {
        throw TransactionCreationException();
      }
      logger.debug('[subaccount] Transaction created successfully');

      final blindedTx = await liquid.blindTransaction(transaction);
      if (blindedTx == null) {
        throw TransactionBlindingException();
      }
      logger.debug('[subaccount] Transaction blinded successfully');

      final signedTx = await liquid.signTransaction(blindedTx);
      if (signedTx == null) {
        throw TransactionSigningException();
      }
      logger.debug('[subaccount] Transaction signed successfully');

      final txId = await liquid.sendTransaction(signedTx);
      if (txId == null) {
        throw TransactionBroadcastException();
      }

      logger.debug(
          "[subaccount] Sweep transaction sent successfully. TxID: $txId");
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      logger.error("[subaccount] Error during sweep: $e");
      state = AsyncError(e, stackTrace);
    }
  }

  Subaccount? _findNativeSegwitLiquidSubaccount() {
    final subaccounts = ref.read(subaccountsProvider).value?.subaccounts ?? [];
    final isTestnet = ref.watch(envProvider) == Env.testnet;

    for (final s in subaccounts) {
      logger.debug(
          '[subaccount] Checking subaccount: ${s.subaccount.pointer}, NetworkType: ${s.networkType}, SubaccountType: ${s.subaccount.type}, UserPath: ${s.subaccount.userPath}');

      if (s.networkType == NetworkType.liquid &&
          s.subaccount.type == GdkSubaccountTypeEnum.type_p2wpkh &&
          s.subaccount.userPath != null &&
          s.subaccount.userPath!.length >= 3 &&
          s.subaccount.userPath![0] ==
              DerivationPathUtils.hardenIndex(84) && // BIP84
          s.subaccount.userPath![1] ==
              DerivationPathUtils.hardenIndex(isTestnet
                  ? 1
                  : 1776) && // Liquid (1 for testnet, 1776 for mainnet)
          s.subaccount.userPath![2] ==
              DerivationPathUtils.hardenIndex(0)) // Main Account
      {
        logger.debug(
            '[subaccount] Found matching native segwit liquid subaccount: ${s.subaccount.pointer}');
        return s;
      }
    }
    logger.debug(
        '[subaccount] No matching native segwit liquid subaccount found');
    return null;
  }

  Subaccount? _findLegacySegwitLiquidSubaccount() {
    final subaccounts = ref.read(subaccountsProvider).value?.subaccounts ?? [];
    return subaccounts.firstWhereOrNull(
      (s) =>
          s.networkType == NetworkType.liquid &&
          s.subaccount.type == GdkSubaccountTypeEnum.type_p2sh_p2wpkh,
    );
  }

  Future<GdkNewTransactionReply?> _createSweepTransaction({
    required Subaccount legacySegwitSubaccount,
    required String receiveAddress,
  }) async {
    final liquid = ref.read(liquidProvider);
    final feeRateKb =
        (ref.read(feeEstimateProvider).getLiquidFeeRate() * 1000).toInt();

    // Create send all transaction
    final transaction = GdkNewTransaction(
      feeRate: feeRateKb,
      addressees: [
        GdkAddressee(
          address: receiveAddress,
          assetId: liquid.policyAsset,
          isGreedy: true,
        ),
      ],
      subaccount: legacySegwitSubaccount.subaccount.pointer,
    );

    return await liquid.createTransaction(transaction: transaction);
  }
}
