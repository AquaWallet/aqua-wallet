import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

class SwapOrderSideSheet extends StatelessWidget {
  const SwapOrderSideSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final aquaColors = context.aquaColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                AquaText.subtitleSemiBold(text: loc.swapOrders),
                AquaIcon.close(
                  color: aquaColors.textPrimary,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 32, top: 16),
            child: StylizedDivider(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: aquaColors.surfacePrimary,
                    ),
                    child: Column(
                      children: [
                        AquaListItem(
                          title: loc.status,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: 'Invoice Set',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzInvoiceAmount,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: '33,000',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.createdAt,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: 'Jan 17, 2025 3:45 PM',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzTimeoutBlockHeight,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: '322199',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzId,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitle: 'bArmJxFZh9PK',
                          subtitleColor: aquaColors.textSecondary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () async => context.copyToClipboard(
                            'bArmJxFZh9PK',
                          ),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.lightningInvoice,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          contentWidget: AquaColoredText(
                            text:
                                'lnbc1m1pnhdq34sp5k7de9vs0uplc0lr63dk8340t58...53v9t3ch4hjjqqdhgdp7',
                            style: AquaAddressTypography.body2.copyWith(
                              color: aquaColors.textSecondary,
                            ),
                            // colorType: ColoredTextEnum.coloredIntegers,
                          ),
                          onTap: () => context.copyToClipboard(
                              'lnbc1m1pnhdq34sp5k7de9vs0uplc0lr63dk8340t58...53v9t3ch4hjjqqdhgdp7'),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzClaimTx,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitle: 'Not available',
                          subtitleColor: aquaColors.textSecondary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () async => context.copyToClipboard(
                            'Not available',
                          ),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzCopySwapData,
                          titleColor: aquaColors.accentBrand,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () async => context.copyToClipboard(
                            'Boltz data',
                          ),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzClaimSwap,
                          titleColor: aquaColors.accentBrand,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () async => context.copyToClipboard(
                            'Claim swap',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
