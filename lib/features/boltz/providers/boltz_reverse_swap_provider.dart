import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/receive/pages/models/models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';
import 'package:decimal/decimal.dart';

final _logger = CustomLogger(FeatureFlag.receive);

// NOTE: This is the home for new Reverse Swap functionality via Boltz Swap.
// Initially only isolating the functional components from legacy setup here.
// However, the end goal is to declutter everything and collect into a single
// AsyncNotifier provider instead of scattered business logic.

/// Failures that block invoice generation, surfaced by the receive screen as an
/// error prompt.
final boltzReverseSwapErrorProvider = StateNotifierProvider.autoDispose<
    BoltzReverseSwapErrorNotifier, BoltzException?>(
  (_) => BoltzReverseSwapErrorNotifier(),
);

class BoltzReverseSwapErrorNotifier extends StateNotifier<BoltzException?> {
  BoltzReverseSwapErrorNotifier() : super(null);

  void report(BoltzException exception) => state = exception;

  void clear() => state = null;
}

// ANCHOR - Reverse Swap Provider
final boltzReverseSwapProvider = StateNotifierProvider.autoDispose<
    BoltzReverseSwapNotifier, ReceiveBoltzState>(BoltzReverseSwapNotifier.new);

class BoltzReverseSwapNotifier extends StateNotifier<ReceiveBoltzState> {
  BoltzReverseSwapNotifier(this._ref)
      : super(const ReceiveBoltzState.enterAmount());

  final Ref _ref;

  Future<void> generateInvoice(
      Decimal amountAsDecimal, AppLocalizations loc) async {
    late final ReverseFeesAndLimits reverseFees;
    try {
      final fees = await _ref.read(boltzFeesProvider(SwapType.reverse).future);
      reverseFees = await requireBoltzService(fees.reverse);
    } catch (e) {
      _logger.error('Boltz Reverse Swap generateInvoice error', e);
      setError(BoltzException.fromError(e));
      return;
    }

    final formatter = _ref.read(formatProvider);
    final unitsProvider = _ref.read(displayUnitsProvider);
    final currentUnit = unitsProvider.currentDisplayUnit;
    final displayUnitTicker = currentUnit.value;

    if (amountAsDecimal < Decimal.fromBigInt(reverseFees.lbtcLimits.minimal)) {
      final minAmountFormatted = formatter.formatAssetAmount(
        amount: reverseFees.lbtcLimits.minimal.toInt(),
        asset: Asset.btc(),
        displayUnitOverride: currentUnit,
      );

      setErrorMessage(
          loc.amountBelowMin(minAmountFormatted, displayUnitTicker));
      return;
    }
    if (amountAsDecimal > Decimal.fromBigInt(reverseFees.lbtcLimits.maximal)) {
      final maxAmountFormatted = formatter.formatAssetAmount(
        amount: reverseFees.lbtcLimits.maximal.toInt(),
        asset: Asset.btc(),
        displayUnitOverride: currentUnit,
      );

      setErrorMessage(
          loc.boltzMaxAmountError(maxAmountFormatted, displayUnitTicker));
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
        index: BigInt.zero,
        outAmount: BigInt.from(amountAsDecimal.toInt()),
        outAddress: address!.address!,
        network: chain,
        electrumUrl: electrumUrl,
        boltzUrl: await _ref.read(boltzApiUrlProvider(SwapType.reverse).future),
        referralId: 'AQUA',
      );

      // Log response (masking sensitive data)
      _logger.debug("Boltz Reverse Swap created - ID: ${response.id}, "
          "Amount: ${response.outAmount}, "
          "Address: ${address.address!}");

      final walletId = await _ref.read(currentWalletIdOrThrowProvider.future);
      final swapDbModel = BoltzSwapDbModel.fromV2SwapResponse(
        response,
        walletId: walletId,
      ).copyWith(
        outAddress: address.address!,
        lastKnownStatus: BoltzSwapStatus.created,
      );
      // No TransactionDbModel is created here — for reverse swaps, the
      // TransactionDbModel is only created when the claim tx is broadcast
      // (in updateReverseSwapClaim). This avoids phantom DB entries for
      // invoices that expire or are never paid.
      await _ref.read(boltzStorageProvider.notifier).saveBoltzSwapResponse(
            swapDbModel: swapDbModel,
            keys: response.keys,
            preimage: response.preimage,
          );

      state = ReceiveBoltzState.qrCode(response);
    } catch (e) {
      state = const ReceiveBoltzState.enterAmount();
      _logger.error('Boltz Reverse Swap Error', e);
      setError(BoltzException.fromError(e));
    }
  }

  void setErrorMessage(String? message) {
    _logger.error('Boltz Reverse Swap Error: $message');
    setError(
      BoltzException(
        BoltzExceptionType.custom,
        customMessage: message,
      ),
    );
  }

  void setError(BoltzException exception) {
    _logger.error('Boltz Reverse Swap Error: ${exception.type}');
    _ref.read(boltzReverseSwapErrorProvider.notifier).report(exception);
  }
}
