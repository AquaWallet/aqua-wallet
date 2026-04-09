import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveAmountArguments {
  const ReceiveAmountArguments({
    required this.asset,
    this.swapPair,
    this.minLimit,
    this.maxLimit,
    this.minLimitSats,
    this.maxLimitSats,
    this.onContinuePressed,
    this.isAmountCompulsory = false,
  });

  final Asset asset;
  final SwapPair? swapPair;
  final String? minLimit;
  final String? maxLimit;
  final int? minLimitSats;
  final int? maxLimitSats;
  final VoidCallback? onContinuePressed;
  final bool isAmountCompulsory;
}

class ReceiveAmountScreen extends HookConsumerWidget {
  static const routeName = '/receiveAmountScreen';

  const ReceiveAmountScreen({super.key, required this.args});

  final ReceiveAmountArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyChipKey = useMemoized(GlobalKey.new);
    final errorController = useMemoized(AquaInputErrorController.new);
    final inputNotifier = useMemoized(() {
      return receiveAssetInputStateProvider(args);
    });
    final validationsProvider = useMemoized(() {
      return receiveAssetAmountValidationProvider(args);
    });
    final input = ref.watch(inputNotifier).valueOrNull;
    final validationState = ref.watch(validationsProvider);
    final isValidAmount = !validationState.hasError &&
        !validationState.isLoading &&
        validationState.valueOrNull == true;
    final isDarkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final decimalSeparator = input?.rate.currency.format.decimalSeparator ??
        MnemonicKeyboardKey.kDecimalCharacter;
    final amountController = useTextEditingController(
      text: input?.amountFieldText,
    );
    final isStableCoin = args.asset.isNonSatsAsset;

    if (input == null) {
      return const SizedBox.shrink();
    }

    final isContinueButtonEnabled = useMemoized(
      () => isValidAmount,
      [isValidAmount],
    );

    final tooltipError = validationState.hasError
        ? ref.watch(assetValidationErrorProvider(
            AssetValidationErrorParams(
              exception: validationState.error as ExceptionLocalized?,
              context: context,
              decoratorType: TooltipExceptionDecorator,
              balanceDisplay: input.balanceDisplay,
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
            ),
          ))
        : null;

    useEffect(() {
      if (inputFieldError != null) {
        errorController.addError(inputFieldError);
      } else {
        errorController.clearError();
      }
      return null;
    }, [inputFieldError]);

    final handleTypeSwap = useCallback(
      (AquaAssetInputType type) {
        final newText =
            ref.read(inputNotifier.notifier).setTypeAndGetControllerText(type);
        if (newText != amountController.text) {
          amountController.text = newText;
        }
      },
      [inputNotifier, amountController],
    );

    useEffect(() {
      //NOTE - The amount textfield has a bi-directional binding to the input
      //provider i.e. when the textfield changes, the input provider is updated
      //with the new value while the derrived data inside the input provider's
      //state can also change the textfield content.
      //This listener updates the input provider when the textfield changes.
      void listener() => ref
          .read(inputNotifier.notifier)
          .updateAmountFieldText(amountController.text);

      amountController.addListener(listener);
      return () => amountController.removeListener(listener);
    }, [amountController]);

    return Theme(
      data: isDarkMode
          ? ref.watch(newDarkThemeProvider(context))
          : ref.watch(newLightThemeProvider(context)),
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          title: context.loc.setAmount,
          colors: context.aquaColors,
          onBackPressed: () {
            if (args.isAmountCompulsory == true) {
              context.popUntilPath(ReceiveMenuScreen.routeName);
            } else {
              context.pop();
            }
          },
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 22),
                //ANCHOR - Fiat Currency Picker
                if (!isStableCoin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: UnitCurrencyChip(
                      key: currencyChipKey,
                      asset: args.asset,
                      rate: input.rate,
                      unit: input.cryptoUnit,
                      showUnit: args.asset.hasFiatRate && input.isCryptoInput,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                //ANCHOR - Amount Input
                AquaCard.surface(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: AquaAssetInputField(
                    key: ValueKey(amountController.text),
                    controller: amountController,
                    errorController: errorController,
                    assetId: args.asset.id,
                    assetIconUrl: args.asset.logoUrl,
                    ticker: args.asset.ticker,
                    type: input.inputType,
                    unit: input.cryptoUnit,
                    balance: input.balanceDisplay,
                    balanceLabel: context.loc.balanceLabel,
                    conversionAmount: input.displayConversionAmount,
                    fiatSymbol: input.rate.currency.format.symbol,
                    showCaret: false,
                    isShowBalance: false,
                    showFiatRate: args.asset.hasFiatRate,
                    isSwapable: !args.asset.isAnyUsdt,
                    colors: context.aquaColors,
                    decimalSeparator: decimalSeparator,
                    onClear: ref.read(inputNotifier.notifier).clearInput,
                    onInputTypeSwap: handleTypeSwap,
                    onUnitSelected: ref.read(inputNotifier.notifier).setUnit,
                  ),
                ),
                const SizedBox(height: 16),
                if (args.minLimitSats != null && args.maxLimitSats != null)
                  AssetAmountLimitsDisplay(
                    args: args,
                    minLimitSats: args.minLimitSats!,
                    maxLimitSats: args.maxLimitSats!,
                  )
                else if (args.minLimit != null && args.maxLimit != null)
                  AssetAmountLimitsDisplay.static(
                    minLimit: args.minLimit!,
                    maxLimit: args.maxLimit!,
                  ),
                const Spacer(),
                if (tooltipError?.isNotEmpty == true) ...[
                  AquaChipLabel(
                    message: tooltipError!,
                    colors: context.aquaColors,
                    maxLines: 2,
                    variant: AquaChipLabelVariant.error,
                  ),
                ],
                //ANCHOR - Numpad
                AquaNumpad(
                  decimalAllowed: input.isFiatInput || !input.isSatsUnit,
                  onKeyPressed: (key) => amountController.addKey(
                    key,
                    decimalSeparator: decimalSeparator,
                  ),
                  decimalSeparator: decimalSeparator,
                  colors: context.aquaColors,
                ),
                const SizedBox(height: 16),
                //ANCHOR - Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: AquaButton.primary(
                    key: ReceiveAssetKeys.receiveAssetConfirmButton,
                    onPressed: isContinueButtonEnabled
                        ? () {
                            ref.read(inputNotifier.notifier).submitAmount();
                            args.onContinuePressed?.call();
                            context.pop();
                          }
                        : null,
                    text: args.asset.isLightning
                        ? context.loc.boltzGenerateInvoice
                        : context.loc.createAddress,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
