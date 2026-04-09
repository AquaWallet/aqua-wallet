import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SendAssetAmountPage extends HookConsumerWidget {
  const SendAssetAmountPage({
    super.key,
    required this.onContinuePressed,
    required this.args,
  });

  final VoidCallback onContinuePressed;
  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final currencyChipKey = useMemoized(GlobalKey.new);
    final provider = useMemoized(() => sendAssetInputStateProvider(args));
    final notifier = useMemoized(() => ref.read(provider.notifier));
    final input = ref.watch(provider).valueOrNull;

    //NOTE: The input state is null for a few milliseconds at the startup,
    // This check avoids a crash. Circular progress indicator is almost not shown.
    if (input == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSatsAsset = input.asset.isSatsAsset;
    final validationsProvider = useMemoized(() {
      return sendAssetAmountValidationProvider(args);
    });
    final errorController = useMemoized(AquaInputErrorController.new);
    final constraints =
        ref.watch(sendAssetAmountConstraintsProvider(args)).valueOrNull;

    // Check if validation passes (no exception thrown)
    final validationState = ref.watch(validationsProvider);
    final isValidAmount = !validationState.hasError &&
        !validationState.isLoading &&
        validationState.valueOrNull == true;
    final decimalSeparator = input.rate.currency.format.decimalSeparator;
    final controllerText = input.amountFieldText;
    final controller = useTextEditingController(text: controllerText);
    final showLightningConstraints = input.asset.isLightning &&
        input.isFiatDisplayAmountAvailable &&
        !input.isLnurlPayFixedAmount &&
        constraints != null;

    // Handle validation errors from exceptions
    final tooltipError = validationState.hasError
        ? ref.watch(assetValidationErrorProvider(
            AssetValidationErrorParams(
              exception: validationState.error as ExceptionLocalized?,
              context: context,
              decoratorType: TooltipExceptionDecorator,
              balanceDisplay: input.balanceDisplay,
              sendInput: input,
            ),
          ))
        : null;
    final inputFieldError = validationState.hasError
        ? ref.watch(assetInputFieldErrorProvider(
            AssetValidationErrorParams(
              exception: validationState.error as ExceptionLocalized?,
              context: context,
              decoratorType: InputFieldExceptionDecorator,
              balanceDisplay: input.balanceDisplay,
              sendInput: input,
            ),
          ))
        : null;

    final debouncedErrors = ref.watch(debouncedValidationErrorsProvider(args));

    useEffect(() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ref
            .read(debouncedValidationErrorsProvider(args).notifier)
            .updateErrors(tooltipError, inputFieldError);
      });
      return null;
    }, [tooltipError, inputFieldError]);

    useEffect(() {
      if (debouncedErrors.inputFieldError != null) {
        errorController.addError(debouncedErrors.inputFieldError!);
      } else {
        errorController.clearError();
      }
      return null;
    }, [debouncedErrors.inputFieldError]);

    final handleTypeSwap = useCallback(
      (AquaAssetInputType type) {
        final newText = ref.read(provider.notifier).setType(type);
        if (newText != controller.text) {
          controller.text = newText;
        }
      },
      [provider, controller],
    );

    useEffect(() {
      final newText = input.amountFieldText ?? '';
      if (newText != controller.text) {
        controller.text = newText;
      }
      return null;
    }, [input.amountFieldText]);

    useEffect(() {
      //NOTE - The amount textfield has a bi-directional binding to the input
      //provider i.e. when the textfield changes, the input provider is updated
      //with the new value while the derrived data inside the input provider's
      //state can also change the textfield content.
      //This listener updates the input provider when the textfield changes.
      void listener() {
        final currentState = ref.read(provider).value;
        if (currentState == null) return;

        final formattedCurrentText =
            ref.read(amountInputServiceProvider).getFormattedAmountFieldText(
                  amountFieldText: input.amountFieldText,
                  rate: input.rate,
                );

        if (formattedCurrentText == null) {
          if (controller.text.isNotEmpty) {
            ref.read(provider.notifier).updateAmountFieldText(controller.text);
          }
        } else {
          // Strip thousands separators for comparison
          final textWithoutThousands = formattedCurrentText.replaceAll(
              currentState.rate.currency.format.thousandsSeparator, '');
          if (controller.text != textWithoutThousands) {
            ref.read(provider.notifier).updateAmountFieldText(controller.text,
                isSendAllFunds: currentState.isSendAllFunds);
          } else if (controller.text.isEmpty) {
            ref.read(provider.notifier).updateAmountFieldText('');
          }
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller, provider]);

    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //ANCHOR - Use All Funds Button
                if (input.asset.shouldShowUseAllFundsButton &&
                    input.balanceInSats > 0) ...{
                  AquaChip.accent(
                    label: context.loc.maxAmount,
                    onTap: () async {
                      await notifier.setSendMaxAmount(true);
                      onContinuePressed();
                    },
                  ),
                } else ...{
                  const SizedBox.shrink()
                },
                //ANCHOR - Fiat Currency Picker
                if (isSatsAsset) ...[
                  UnitCurrencyChip(
                    key: currencyChipKey,
                    asset: args.asset,
                    rate: input.rate,
                    unit: input.cryptoUnit,
                    showUnit:
                        args.asset.hasFiatRate && input.isCryptoAmountInput,
                  ),
                ]
              ],
            ),
            const SizedBox(height: 14),
            //ANCHOR - Amount Input
            AquaCard.surface(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: AquaAssetInputField(
                key: ValueKey(controller.text),
                controller: controller,
                errorController: errorController,
                assetId: args.asset.id,
                assetIconUrl:
                    !args.asset.isInternal ? args.asset.logoUrl : null,
                ticker: args.asset.ticker,
                type: input.inputType,
                unit: input.cryptoUnit,
                balance: input.balanceDisplay,
                balanceLabel: context.loc.balanceLabel,
                conversionAmount: input.displayConversionAmount ?? '',
                usdtCryptoAmount: input.usdtCryptoAmount,
                fiatSymbol: input.rate.currency.format.symbol,
                isUsdCurrency: input.rate.currency.isUsd,
                showUsdtConversion: false,
                showCaret: false,
                showFiatRate: args.asset.hasFiatRate,
                isSwapable: isSatsAsset,
                colors: context.aquaColors,
                decimalSeparator: decimalSeparator,
                precision: input.precision,
                onClear: () => notifier.updateAmountFieldText(''),
                onInputTypeSwap: handleTypeSwap,
                onUnitSelected: notifier.setUnit,
              ),
            ),
            const SizedBox(height: 2.0),
            //ANCHOR - Min/Max Range Panel
            if (input.asset.isAltUsdt) ...{
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerLeft,
                child: USDtSwapMinMaxPanel(
                  currency: input.rate.currency,
                  swapPair: SwapPair(
                    from: SwapAssetExt.usdtLiquid,
                    to: SwapAsset.fromAsset(input.asset),
                  ),
                ),
              ),
            } else if (showLightningConstraints) ...[
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerLeft,
                child: LightningMinMaxRangePanel(
                  args: args,
                  constraints: constraints,
                ),
              ),
            ],
            const Spacer(),
            if (debouncedErrors.tooltipError?.isNotEmpty == true) ...[
              AquaChipLabel(
                message: debouncedErrors.tooltipError!,
                colors: context.aquaColors,
                maxLines: 2,
                variant: AquaChipLabelVariant.error,
              ),
            ],
            //ANCHOR - Numpad
            AquaNumpad(
              decimalAllowed: input.isFiatAmountInput || !input.isSatsUnit,
              decimalSeparator: decimalSeparator,
              onKeyPressed: (key) => controller.addKey(
                key,
                decimalSeparator: decimalSeparator,
                precision: input.precision,
              ),
              colors: context.aquaColors,
            ),
            const SizedBox(height: 16),
            //ANCHOR - Confirm Button
            SizedBox(
              width: double.infinity,
              child: AquaButton.primary(
                onPressed: isValidAmount ? onContinuePressed : null,
                text: context.loc.next,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
