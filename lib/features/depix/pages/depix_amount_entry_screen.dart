import 'package:aqua/features/depix/providers/depix_amount_entry_provider.dart';
import 'package:aqua/features/depix/providers/depix_amount_formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

class DepixAmountEntryPage extends ConsumerWidget {
  const DepixAmountEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brlFormat = depixBrlFormat.format;
    final state = ref.watch(depixAmountEntryProvider);
    final colors = context.aquaColors;
    final notifier = ref.read(depixAmountEntryProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                            svgAsset: brlFormat.flagSvg,
                            size: 16,
                          ),
                          label: depixBrlFormat.value,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: notifier.toggleReversed,
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
                          text: state.primaryLine,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        _DepixConversionSlot(colors: colors, state: state),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AquaNumpad(
            colors: colors,
            decimalSeparator: brlFormat.decimalSeparator,
            onKeyPressed: notifier.addKey,
          ),
          const SizedBox(height: 8),
          AquaButton.primary(
            onPressed: state.canContinue ? notifier.submitDeposit : null,
            text: context.loc.next,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DepixConversionSlot extends StatelessWidget {
  const _DepixConversionSlot({required this.colors, required this.state});

  final AquaColors colors;
  final DepixAmountEntryState state;

  @override
  Widget build(BuildContext context) {
    if (state.hasError) {
      return AquaText.body1Medium(
        text: context.loc.somethingWentWrong,
        color: colors.accentDanger,
        textAlign: TextAlign.center,
      );
    }

    if (state.conversionLine != null) {
      return AquaText.body1Medium(
        text: state.conversionLine!,
        color: colors.textSecondary,
        textAlign: TextAlign.center,
      );
    }

    if (!state.isLoading) return const SizedBox.shrink();

    return Skeletonizer(
      enabled: true,
      child: Skeleton.shade(
        child: Container(
          width: 120,
          height: 20,
          decoration: BoxDecoration(
            color: colors.surfaceTertiary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
