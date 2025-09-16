import 'package:coin_cz/common/decimal/decimal_ext.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/receive/pages/models/models.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:decimal/decimal.dart';

final _logger = CustomLogger(FeatureFlag.receive);

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

  Future<void> generateInvoice(
      Decimal amountAsDecimal, AppLocalizations loc) async {
    if (amountAsDecimal < Decimal.fromInt(boltzMin)) {
      setErrorMessage(loc.amountBelowMin(boltzMin));
      return;
    }
    if (amountAsDecimal > Decimal.fromInt(boltzMax)) {
      setErrorMessage(loc.boltzMaxAmountError(boltzMax));
      return;
    }

    await create(amountAsDecimal);
  }

  Future<void> create(Decimal amountAsDecimal) async {
    try {
      state = const ReceiveBoltzState.generatingInvoice();

      if (amountAsDecimal == Decimal.zero) {
        _logger.error("amount as double is zero");
        return;
      }

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
        referralId: 'COIN.CZ',
      );

      // Mask sensitive data before logging
      final maskedResponse = response.copyWith(
        keys: response.keys.copyWith(
          secretKey: '********',
        ),
        preimage: PreImage(
          value: '********',
          sha256: response.preimage.sha256,
          hash160: response.preimage.hash160,
        ),
      );

      _logger.debug("Boltz Reverse Swap response: $maskedResponse");

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
      _logger.error('Boltz Reverse Swap Error', e);
      setErrorMessage(e.toString());
    }
  }

  void setErrorMessage(String? message) {
    _logger.error('Boltz Reverse Swap Error: $message');
    _ref.read(boltzReverseSwapUiErrorProvider.notifier).state = message;
  }
}
