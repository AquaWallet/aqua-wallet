import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class AquaAssetInputField extends HookWidget {
  const AquaAssetInputField({
    super.key,
    required this.assetId,
    required this.ticker,
    required this.unit,
    required this.assets,
    required this.fiatConversionRate,
    this.type = AquaAssetInputType.crypto,
    this.fiatSymbol = '\$',
    this.balance = 0,
    this.showDropdown = true,
    this.isSwapable = true,
    this.disabled = false,
    this.errorController,
    this.colors,
    this.controller,
    this.onChanged,
    this.onAssetSelected,
  });

  final String assetId;
  final String ticker;
  final double balance;
  final double fiatConversionRate;
  final AquaAssetInputType type;
  final AquaAssetInputUnit unit;
  final String fiatSymbol;
  final bool showDropdown;
  final bool isSwapable;
  final AquaInputErrorController? errorController;
  final bool disabled;
  final TextEditingController? controller;
  final void Function(String valueInCrypto)? onChanged;
  final Function(String)? onAssetSelected;
  final AquaColors? colors;
  final List<AssetUiModel> assets;

  static const kFadeDuration = Duration(milliseconds: 200);
  static const kUpdateDelay = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final type = useState(this.type);
    final isUsdt = AssetIds.isAnyUsdt(assetId);
    final isCryptoInput = type.value == AquaAssetInputType.crypto;
    final isInputVisible = useState(true);
    final isConvertedVisible = useState(true);

    // Create or use provided error controller
    final errorController = useMemoized(
      () => this.errorController ?? AquaInputErrorController(''),
    );

    // State to hold current error and visibility
    final currentError = useState<String?>(errorController.currentError);
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

    // Convert balance and max error to fiat when needed
    final displayBalance = useMemoized(() {
      if (isUsdt || isCryptoInput) return balance.toString();
      return (balance * fiatConversionRate).toStringAsFixed(2);
    }, [balance, fiatConversionRate, isCryptoInput, isUsdt]);

    final controller = useTextEditingController(text: this.controller?.text);
    final content = useValueListenable(controller);
    final overlayEntry = useState<OverlayEntry?>(null);

    final onAmountCleared = useCallback(() {
      controller.clear();
      onChanged?.call('');
    });

    // Calculate converted amount based on input and conversion rate
    final convertedAmount = useMemoized(() {
      if (content.text.isEmpty) return 0.0;
      try {
        final amount = double.parse(content.text);
        return isCryptoInput
            ? amount * fiatConversionRate
            : amount / fiatConversionRate;
      } catch (e) {
        return 0.0;
      }
    }, [content.text, fiatConversionRate, type.value]);

    // Convert input value to crypto for onChanged callback
    final onInputChanged = useCallback((String value) {
      if (value.isEmpty) {
        onChanged?.call('');
        return;
      }

      final amount = double.parse(value);
      final cryptoValue = isCryptoInput ? amount : amount / fiatConversionRate;
      onChanged?.call(cryptoValue.toStringAsFixed(8));
    }, [type.value, fiatConversionRate, onChanged]);

    final onSwapType = useCallback(() {
      if (content.text.isEmpty) {
        type.value =
            isCryptoInput ? AquaAssetInputType.fiat : AquaAssetInputType.crypto;
        return;
      }

      // Hide both fields
      isInputVisible.value = false;
      isConvertedVisible.value = false;

      // After fields are hidden, update the type and values
      Future.delayed(kUpdateDelay, () {
        type.value =
            isCryptoInput ? AquaAssetInputType.fiat : AquaAssetInputType.crypto;
        controller.text =
            convertedAmount.toStringAsFixed(isCryptoInput ? 2 : 8);

        final cryptoValue = isCryptoInput
            ? convertedAmount / fiatConversionRate
            : convertedAmount;
        onChanged?.call(cryptoValue.toStringAsFixed(8));

        // Show fields with new values
        isInputVisible.value = true;
        isConvertedVisible.value = true;
      });
    }, [content.text, convertedAmount, type.value, fiatConversionRate]);

    final onAssetSelectorTap = useCallback(() {
      if (overlayEntry.value != null) {
        overlayEntry.value?.remove();
        overlayEntry.value = null;
        return;
      }

      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final buttonPos = box.localToGlobal(Offset.zero);

      // Get screen size
      final screenHeight = MediaQuery.of(context).size.height;
      // Calculate available height below the button
      final availableHeight = screenHeight - (buttonPos.dy + box.size.height);

      final entry = OverlayEntry(
        builder: (context) => Positioned(
          top: buttonPos.dy + (box.size.height / 2) + 4,
          left: buttonPos.dx,
          child: AquaAssetSelectorContent(
            selectedAssetId: assetId,
            assets: assets,
            renderBox: box,
            overlayEntry: overlayEntry,
            availableHeight: availableHeight,
            onAssetSelected: (selectedAssetId) {
              // Clear input when asset changes
              controller.clear();
              onChanged?.call('');
              onAssetSelected?.call(selectedAssetId);
            },
            colors: colors,
          ),
        ),
      );

      overlayEntry.value = entry;
      Overlay.of(context).insert(entry);
    }, [assets, assetId, colors, onAssetSelected, controller, onChanged]);

    return Opacity(
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
                        key: ValueKey('input_${type.value}'),
                        type: isUsdt ? AquaAssetInputType.crypto : type.value,
                        fiatSymbol: fiatSymbol,
                        onChanged: onInputChanged,
                        controller: controller,
                        colors: colors,
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
                  //ANCHOR - Asset Selector Button
                  AquaAssetInputSwitch(
                    assetId: assetId,
                    ticker: ticker,
                    unit: unit,
                    showDropdown: showDropdown,
                    colors: colors,
                    onTap: onAssetSelectorTap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //ANCHOR - Converted Amount
                  if (!isUsdt) ...[
                    InkWell(
                      onTap: onSwapType,
                      child: Row(
                        children: [
                          AnimatedOpacity(
                            duration: kFadeDuration,
                            curve: Curves.easeInOut,
                            opacity: isConvertedVisible.value ? 1 : 0,
                            child: AquaText.body2Medium(
                              key: ValueKey('converted_${type.value}'),
                              text: isCryptoInput
                                  ? '$fiatSymbol${convertedAmount.toStringAsFixed(2)}'
                                  : convertedAmount.toStringAsFixed(8),
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
                  ],
                  const SizedBox(width: 16),
                  AnimatedSwitcher(
                    duration: kFadeDuration,
                    layoutBuilder: (currChild, prevChildren) => Stack(
                      alignment: Alignment.centerRight,
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
                        child: child,
                      ),
                    ),
                    child: isErrorVisible.value && currentError.value != null
                        ? AquaText.body2Medium(
                            key: ValueKey(currentError.value),
                            text: currentError.value!.contains('Insufficient')
                                ? isCryptoInput || isUsdt
                                    ? context.loc.balanceValue(displayBalance)
                                    : context.loc.balanceValue(
                                        '$fiatSymbol$displayBalance')
                                : currentError.value!,
                            color: colors?.accentDanger,
                          )
                        : AquaText.body2Medium(
                            key: const ValueKey('balance'),
                            text: isCryptoInput || isUsdt
                                ? context.loc.balanceValue(displayBalance)
                                : context.loc
                                    .balanceValue('$fiatSymbol$displayBalance'),
                            color: colors?.textSecondary,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
