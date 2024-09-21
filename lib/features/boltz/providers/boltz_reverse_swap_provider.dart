import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/receive/pages/models/models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:decimal/decimal.dart';

// NOTE: This is the home for new Reverse Swap functionality via Boltz Swap.
// Initially only isolating the functional components from legacy setup here.
// However, the end goal is to declutter everything and collect into a single
// AsyncNotifier provider instead of scattered business logic.

// ANCHOR - Reverse Swap UI Error
final boltzReverseSwapUiErrorProvider =
    StateProvider.autoDispose<String?>((_) => null);

// ANCHOR - Reverse Swap Provider
final boltzReverseSwapProvider = StateNotifierProvider.autoDispose<
    BoltzReverseSwapNotifier, ReceiveBoltzState>(BoltzReverseSwapNotifier.new);

class BoltzReverseSwapNotifier extends StateNotifier<ReceiveBoltzState> {
  BoltzReverseSwapNotifier(this._ref)
      : super(const ReceiveBoltzState.enterAmount());

  final Ref _ref;

  Future<void> create(Decimal amountAsDecimal) async {
    try {
      state = const ReceiveBoltzState.generatingInvoice();

      if (amountAsDecimal == Decimal.zero) {
        logger.e("[Receive] amount as double is zero");
        return;
      }

      // REVIEW: Is this the right way to get the electrum url?
      final network = await _ref.read(liquidProvider).getNetwork();
      final electrumUrl = network!.electrumUrl!;

      final mnemonic = await _ref.read(liquidProvider).generateMnemonic12();
      final mnemonicString = mnemonic!.join(' ');

      // create the fallback liquid receive address in case this is a boltz-to-boltz "magic routing hint" send
      final address = await _ref.read(liquidProvider).getReceiveAddress();

      final chain = _ref.read(envProvider) == Env.mainnet
          ? Chain.liquid
          : Chain.liquidTestnet;
      final response = await LbtcLnSwap.newReverse(
        mnemonic: mnemonicString,
        index: 0,
        outAmount: amountAsDecimal.toInt(),
        outAddress: address!.address!,
        network: chain,
        electrumUrl: electrumUrl,
        boltzUrl: _ref.read(boltzEnvConfigProvider).apiUrl,
        referralId: 'AQUA',
      );

      logger.d("[Receive] Boltz Reverse Swap response: $response");

      final swapDbModel =
          BoltzSwapDbModel.fromV2SwapResponse(response).copyWith(
        outAddress: address.address!,
        lastKnownStatus: BoltzSwapStatus.created,
      );
      final transactionDbModel = TransactionDbModel.fromV2SwapResponse(
        txhash: "",
        assetId: Asset.lightning().id,
        swap: response,
        // this will be settle address if resolves as a boltz-to-boltz swap. if a regular ln swap, claim address will be settle address.
        settleAddress: address.address!,
      );
      await _ref.read(boltzStorageProvider.notifier).saveBoltzSwapResponse(
            txnDbModel: transactionDbModel,
            swapDbModel: swapDbModel,
            keys: response.keys,
            preimage: response.preimage,
          );

      state = ReceiveBoltzState.qrCode(response);
    } catch (e) {
      state = const ReceiveBoltzState.enterAmount();
      logger.e('[Receive] Boltz Reverse Swap Error', e);
      setErrorMessage(e.toString());
    }
  }

  void setErrorMessage(String? message) {
    logger.e('[Receive] Boltz Reverse Swap Error: $message');
    _ref.read(boltzReverseSwapUiErrorProvider.notifier).state = message;
  }
}
