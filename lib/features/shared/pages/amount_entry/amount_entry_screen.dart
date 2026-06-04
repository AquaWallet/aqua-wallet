import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

class AmountEntryScreenProps {
  const AmountEntryScreenProps({
    this.title = '',
    required this.spec,
    required this.buttonText,
    required this.onContinue,
    required this.isContinueEnabled,
    this.topSlot,
    this.onBack,
    this.onCurrencyChipPressed,
    this.onInputDirectionChanged,
    this.decimalSeparator,
    this.decimalAllowed = true,
  });

  final String title;
  final AmountEntrySpec spec;
  final String buttonText;
  final void Function(double inputAmount, bool isReversed) onContinue;
  final bool Function(double inputAmount, bool isReversed) isContinueEnabled;
  final Widget? topSlot;
  final VoidCallback? onBack;
  final VoidCallback? onCurrencyChipPressed;
  final ValueChanged<bool>? onInputDirectionChanged;
  final String? decimalSeparator;
  final bool decimalAllowed;
}

/// The interactive body of the amount entry screen — no Scaffold or AppBar.
/// Use this when embedding in a PageView or another Scaffold.
/// Use [AmountEntryScreen] for the standalone full-screen version.
class AmountEntryBody extends HookConsumerWidget {
  const AmountEntryBody({super.key, required this.props});

  final AmountEntryScreenProps props;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = props.spec;
    final buttonText = props.buttonText;
    final onContinue = props.onContinue;
    final topSlot = props.topSlot;
    final onCurrencyChipPressed = props.onCurrencyChipPressed;
    final onInputDirectionChanged = props.onInputDirectionChanged;
    final decimalSeparator = props.decimalSeparator;
    final decimalAllowed = props.decimalAllowed;
    final isContinueEnabled = props.isContinueEnabled;

    final format = ref.watch(formatProvider);
    final formatter = ref.watch(formatterProvider);
    final amountInputService = ref.watch(amountInputServiceProvider);
    final focusNode = useFocusNode();
    final controller = useTextEditingController();
    final textUpdates = useListenable(controller);
    final isReversed = useState(false);

    final effectiveDecimalSeparator =
        decimalSeparator ?? spec.fiat.format.decimalSeparator;

    final parseFormatSpec = amountEntryParseFormatSpec(spec, decimalSeparator);

    final inputAmount = useMemoized(
      () {
        final raw = controller.text.trim();
        if (raw.isEmpty) return 0.0;
        final cleaned = formatter.cleanAmountString(raw, parseFormatSpec);
        return double.tryParse(cleaned) ?? 0.0;
      },
      [textUpdates.text, parseFormatSpec, formatter],
    );

    final canContinue = isContinueEnabled(inputAmount, isReversed.value);

    final onNumpadKeyPressed = useCallback(
      (MnemonicKeyboardKey key) {
        controller.addKey(
          key,
          decimalSeparator: effectiveDecimalSeparator,
          precision: spec.fiat.format.decimalPlaces,
        );
      },
      [controller, effectiveDecimalSeparator, spec.fiat.format.decimalPlaces],
    );

    useEffect(() {
      void listener() {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    final amountLines = amountEntryComputeLines(
      format: format,
      amountInputService: amountInputService,
      spec: spec,
      inputAmount: inputAmount,
      isReversed: isReversed.value,
      rawFieldText: controller.text,
    );

    final colors = context.aquaColors;

    final onDirectionSwapPressed = useCallback(
      () {
        final before = isReversed.value;
        controller.text = amountEntryTextAfterDirectionToggle(
          inputAmount,
          before,
          spec,
          format,
        );
        isReversed.value = !before;
        onInputDirectionChanged?.call(isReversed.value);
      },
      [
        controller,
        inputAmount,
        isReversed,
        spec,
        format,
        onInputDirectionChanged,
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topSlot != null) ...[
            topSlot,
            const SizedBox(height: 8),
          ],
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(child: SizedBox.shrink()),
                        AquaChip(
                          colors: colors,
                          compact: true,
                          leadingIcon: CountryFlag(
                            svgAsset: spec.fiat.format.flagSvg,
                            size: 16,
                          ),
                          label: spec.fiat.value,
                          onTap: onCurrencyChipPressed,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onDirectionSwapPressed,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: AquaUiAssets.svgs.switching.svg(
                                    width: 18,
                                    height: 18,
                                    colorFilter: ColorFilter.mode(
                                      colors.textSecondary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AquaText.h3SemiBold(
                          text: amountLines.primaryLine,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        AquaText.body1Medium(
                          text: amountLines.conversionLine,
                          color: colors.textSecondary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AquaNumpad(
            colors: colors,
            decimalAllowed: decimalAllowed,
            decimalSeparator: effectiveDecimalSeparator,
            onKeyPressed: onNumpadKeyPressed,
          ),
          const SizedBox(height: 8),
          AquaButton.primary(
            onPressed: canContinue
                ? () => onContinue(inputAmount, isReversed.value)
                : null,
            text: buttonText,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Standalone full-screen amount entry. Provides its own Scaffold and AppBar.
/// For embedding in a PageView or flow, use [AmountEntryBody] directly.
class AmountEntryScreen extends StatelessWidget {
  const AmountEntryScreen({super.key, required this.props});

  final AmountEntryScreenProps props;

  @override
  Widget build(BuildContext context) {
    final colors = context.aquaColors;
    return Scaffold(
      appBar: AquaTopAppBar(
        colors: colors,
        title: props.title,
        onBackPressed: props.onBack ?? () => context.pop(),
      ),
      body: SafeArea(
        child: AmountEntryBody(props: props),
      ),
    );
  }
}
