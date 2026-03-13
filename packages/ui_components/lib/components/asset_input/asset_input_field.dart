import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaAssetInputField extends HookWidget {
  const AquaAssetInputField({
    super.key,
    required this.assetId,
    this.assetIconUrl,
    required this.ticker,
    required this.unit,
    this.assets = const [],
    required this.balance,
    required this.balanceLabel,
    required this.conversionAmount,
    this.usdtCryptoAmount,
    this.type = AquaAssetInputType.crypto,
    this.fiatSymbol = '\$',
    this.showCaret = true,
    this.isSwapable = true,
    this.showFiatRate = false,
    this.disabled = false,
    this.isShowBalance = true,
    this.errorController,
    this.colors,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onAssetSelected,
    this.onUnitSelected,
    this.onInputTypeSwap,
    this.decimalSeparator = '.',
    this.precision = 8,
    this.isUsdCurrency = false,
    this.showUsdtConversion = false,
  });

  final String assetId;
  final String? assetIconUrl;
  final String ticker;
  final String balance;
  final String balanceLabel;
  final String conversionAmount;
  final AquaAssetInputType type;
  final AquaAssetInputUnit unit;
  final String fiatSymbol;
  final bool showCaret;
  final bool isSwapable;
  final bool showFiatRate;
  final bool isShowBalance;
  final AquaInputErrorController? errorController;
  final bool disabled;
  final TextEditingController? controller;
  final void Function(String valueInCrypto)? onChanged;
  final void Function()? onClear;
  final Function(String)? onAssetSelected;
  final void Function(AquaAssetInputUnit)? onUnitSelected;
  final void Function(AquaAssetInputType type)? onInputTypeSwap;
  final AquaColors? colors;
  final List<AssetUiModel> assets;
  final String decimalSeparator;
  final int precision;
  final String? usdtCryptoAmount;
  final bool isUsdCurrency;
  final bool showUsdtConversion;

  static const kFadeDuration = Duration(milliseconds: 200);
  static const kUpdateDelay = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final isCryptoInput = type == AquaAssetInputType.crypto;
    final isUsdt = AssetIds.isAnyUsdt(assetId);
    final isInputVisible = useState(true);
    final isConvertedVisible = useState(true);

    // Create or use provided error controller
    final errorController = useMemoized(
      () => this.errorController ?? AquaInputErrorController(),
    );

    // State to hold current error and visibility
    final currentError =
        useState<AquaInputError?>(errorController.currentError);
    final isErrorVisible = useState<bool>(errorController.isVisible);

    // Subscribe to error and visibility streams
    useEffect(() {
      final errorSub = errorController.errors.listen((error) {
        currentError.value = error;
      });
      final visibilitySub = errorController.visibility.listen((visible) {
        isErrorVisible.value = visible;
      });
      return () {
        errorSub.cancel();
        visibilitySub.cancel();
      };
    }, [errorController]);

    // Cleanup error controller if we created it internally
    useEffect(() {
      if (this.errorController == null) {
        return () => errorController.dispose();
      }
      return null;
    }, []);

    final internalController =
        useTextEditingController(text: this.controller?.text);
    final controller = this.controller ?? internalController;
    final content = useValueListenable(controller);
    final overlayEntry = useState<OverlayEntry?>(null);

    final onAmountCleared = useCallback(() {
      controller.clear();
      onClear?.call();
    }, [controller, onClear]);

    // Convert input value to crypto for onChanged callback
    final onInputChanged = useCallback((String value) {
      if (value.isEmpty) {
        onChanged?.call('');
        return;
      }

      final amount = double.parse(value);
      onChanged?.call(amount.toStringAsFixed(8));
    }, [onChanged]);

    return PopScope(
      onPopInvoked: (didPop) {
        //Dismiss overlay when exiting the screen
        if (didPop && overlayEntry.value != null) {
          overlayEntry.value?.remove();
          overlayEntry.value = null;
          return;
        }
      },
      child: Opacity(
        opacity: disabled ? .5 : 1,
        child: AbsorbPointer(
          absorbing: disabled,
          child: Container(
            color: colors?.surfacePrimary,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    //ANCHOR - Amount Input
                    Expanded(
                      child: AnimatedOpacity(
                        duration: kFadeDuration,
                        curve: Curves.easeInOut,
                        opacity: isInputVisible.value ? 1 : 0,
                        child: AquaAmountInputTextField(
                          key: ValueKey('input_$type'),
                          type: type,
                          fiatSymbol: fiatSymbol,
                          onChanged: onInputChanged,
                          controller: controller,
                          colors: colors,
                          decimalSeparator: decimalSeparator,
                          precision: precision,
                        ),
                      ),
                    ),
                    //ANCHOR - Clear Button
                    if (content.text.isNotEmpty && !disabled) ...[
                      AquaAssetInputClearButton(
                        colors: colors,
                        onTap: onAmountCleared,
                      ),
                      const SizedBox(width: 16),
                    ],
                    //ANCHOR - Asset Input Unit Selector Button
                    AquaAssetInputSwitch(
                      assetId: assetId,
                      assetIconUrl: assetIconUrl,
                      ticker: ticker,
                      unit: unit,
                      showCaret: isCryptoInput && showFiatRate && showCaret,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //ANCHOR - Converted Amount
                    if (!isUsdt && showFiatRate) ...[
                      InkWell(
                        onTap: () =>
                            WidgetsBinding.instance.addPostFrameCallback(
                          (_) => onInputTypeSwap?.call(
                            isCryptoInput
                                ? AquaAssetInputType.fiat
                                : AquaAssetInputType.crypto,
                          ),
                        ),
                        splashFactory: InkRipple.splashFactory,
                        child: Row(
                          children: [
                            AnimatedOpacity(
                              duration: kFadeDuration,
                              curve: Curves.easeInOut,
                              opacity: isConvertedVisible.value ? 1 : 0,
                              child: AquaText.body2Medium(
                                key: ValueKey('converted_$type'),
                                text: conversionAmount,
                                color: colors?.textSecondary,
                              ),
                            ),
                            //ANCHOR - Swap Button
                            if (isSwapable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: colors?.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: AquaIcon.switching(
                                  color: colors?.textTertiary,
                                  size: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (isUsdt &&
                        !isUsdCurrency &&
                        showUsdtConversion) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            duration: kFadeDuration,
                            curve: Curves.easeInOut,
                            opacity: isConvertedVisible.value ? 1 : 0,
                            child: AquaText.body2Medium(
                              key: ValueKey('usdt_crypto_$type'),
                              text: usdtCryptoAmount ?? '\$0.00',
                              color: colors?.textSecondary,
                            ),
                          ),
                          if (conversionAmount.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            AnimatedOpacity(
                              duration: kFadeDuration,
                              curve: Curves.easeInOut,
                              opacity: isConvertedVisible.value ? 1 : 0,
                              child: AquaText.body2Medium(
                                key: ValueKey('converted_$type'),
                                text: conversionAmount,
                                color: colors?.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(width: 16),
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: kFadeDuration,
                        layoutBuilder: (currChild, prevChildren) => Stack(
                          alignment: AlignmentDirectional.centerEnd,
                          children: [
                            ...prevChildren,
                            if (currChild != null) currChild,
                          ],
                        ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            axisAlignment: -1,
                            sizeFactor: animation,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: child,
                            ),
                          ),
                        ),
                        child:
                            isErrorVisible.value && currentError.value != null
                                ? _BalanceText(
                                    key: ValueKey(currentError.value),
                                    label: currentError.value!.label,
                                    amount: currentError.value!.amount,
                                    color: colors?.accentDanger,
                                  )
                                : isShowBalance
                                    ? _BalanceText(
                                        key: const ValueKey('balance'),
                                        label: balanceLabel,
                                        amount: balance,
                                        color: colors?.textSecondary,
                                      )
                                    : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Renders an optional label (in locale text direction) alongside an optional
// numeric amount (always LTR) as separate widgets, preventing BiDi reversal
// when Arabic labels are mixed with numbers.
class _BalanceText extends StatelessWidget {
  const _BalanceText({
    super.key,
    this.label,
    this.amount,
    this.color,
  });

  final String? label;
  final String? amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;
    final hasAmount = amount != null && amount!.isNotEmpty;

    if (!hasLabel && !hasAmount) return const SizedBox.shrink();

    if (!hasLabel || !hasAmount) {
      return AquaText.body2Medium(
        text: hasAmount ? amount! : label!,
        maxLines: 1,
        color: color,
        textDirection: hasAmount ? TextDirection.ltr : null,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AquaText.body2Medium(text: label!, maxLines: 1, color: color),
        const SizedBox(width: 4),
        AquaText.body2Medium(
          text: amount!,
          maxLines: 1,
          color: color,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
