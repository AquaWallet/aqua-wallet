import 'package:aqua/common/common.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendConfirmationSlider extends HookConsumerWidget {
  const SendConfirmationSlider({
    super.key,
    required this.args,
    required this.onConfirmed,
  });

  final SendAssetArguments args;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txn = ref.watch(sendAssetTxnProvider(args)).valueOrNull;
    final feeAsset =
        ref.watch(sendAssetInputStateProvider(args)).value!.feeAsset;

    //NOTE - Transaction is expected to be unavailable for Taxi fee payment
    final isTaxiFeePayment = feeAsset == FeeAsset.tetherUsdt;
    if (!isTaxiFeePayment && (txn == null || txn is SendAssetTransactionIdle)) {
      return const SizedBox.shrink();
    }

    final sliderState = useState(SliderState.initial);

    // Txn Errors
    final txnInitError =
        ref.watch(sendAssetTransactionSetupProvider(args)).error;
    final txnError = ref.watch(sendAssetTxnProvider(args)).error;
    // Fee Errors
    final feeOptionsError = ref.watch(sendAssetFeeOptionsProvider(args)).error;
    final feeStructureError = ref
        .watch(transactionFeeStructureProvider(args.toFeeStructureArgs()))
        .error;
    // Validation Errors
    final amountValidationState =
        ref.watch(sendAssetAmountValidationProvider(args));
    final isValidAmount = amountValidationState.valueOrNull ?? false;
    final amountError = amountValidationState.error;
    final amountParsingError = amountError as AmountParsingException?;
    final isInsufficientBalance = amountParsingError != null &&
        amountParsingError.type == AmountParsingExceptionType.notEnoughFunds;

    final sliderText = useMemoized(() {
      return switch (null) {
        _ when (txnInitError is ExceptionLocalized) =>
          txnInitError.toLocalizedString(context),
        _ when (txnError is ExceptionLocalized) =>
          txnError.toLocalizedString(context),
        _ when (feeOptionsError is ExceptionLocalized) =>
          feeOptionsError.toLocalizedString(context),
        _ when (feeStructureError is ExceptionLocalized) =>
          feeStructureError.toLocalizedString(context),
        _ when (isInsufficientBalance) => context.loc.notEnoughFunds,
        _ => context.loc.slideToSend,
      };
    }, [
      feeStructureError,
      feeOptionsError,
      txnInitError,
      txnError,
      amountParsingError
    ]);

    final onTransactionConfirm = useCallback(() async {
      sliderState.value = SliderState.inProgress;
      onConfirmed();
    }, []);

    ref.listen(sendAssetTxnProvider(args), (_, state) {
      if (state.hasError) {
        logger.error('[Send] Error', state.error, state.stackTrace);
        sliderState.value = SliderState.error;
      } else {
        sliderState.value = SliderState.initial;
      }

      state.asData?.value.mapOrNull(complete: (args) {
        logger.info('Transaction sent successfully: ${state.asData?.value}');
        sliderState.value = SliderState.completed;
      });
    });

    final isSliderEnabled = useMemoized(
      () {
        return isValidAmount &&
            txnInitError == null &&
            feeOptionsError == null &&
            feeStructureError == null;
      },
      [isValidAmount, txnInitError, feeOptionsError, feeStructureError],
    );

    return SendAssetConfirmSlider(
      enabled: isSliderEnabled,
      sliderState: sliderState.value,
      text: sliderText,
      onConfirm: onTransactionConfirm,
    );
  }
}
