import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class BuySellSideSheet extends HookWidget {
  const BuySellSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.marketplaceScreenBuyButton,
      showBackButton: false,

      ///TODO: Replace with selected region from provider
      addIconNextToClose: Container(
        padding: const EdgeInsets.all(4),
        child: const AquaText.h4SemiBold(
          text: '🇳🇴',
        ),
      ),
      children: [
        OutlineContainer(
          aquaColors: aquaColors,
          borderColor: aquaColors.surfaceBorderSecondary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: AquaListItem(
                  iconLeading: AquaIcon.btcDirect(size: 40),
                  colors: aquaColors,
                  title: 'BTC Direct',
                  titleColor: aquaColors.textPrimary,
                  titleTrailing: '\$86,384.93',
                  titleTrailingColor: aquaColors.textPrimary,
                  subtitleTrailing: 'Incl. Fees',
                  subtitleTrailingColor: aquaColors.textSecondary,
                ),
              ),
              const Divider(height: 0),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: aquaColors.surfaceSecondary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          AquaText.caption1SemiBold(
                            text: loc.marketplaceBuyBitcoinPayWith,
                            color: aquaColors.textSecondary,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 17,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AquaIcon.visa(
                                    size: 14,
                                    colored: true,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: VerticalDivider(
                                      width: 0,
                                      color: aquaColors.surfaceBorderSecondary,
                                    ),
                                  ),
                                  AquaIcon.mastercard(
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 0),
                      ),
                      Row(
                        children: [
                          AquaText.caption1SemiBold(
                              text: loc.marketplaceBuyBitcoinPayWith,
                              color: aquaColors.textSecondary),
                          Expanded(
                            child: SizedBox(
                              height: 17,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AquaAssetIcon.fromAssetId(
                                    assetId: AssetIds.usdtTether,
                                    size: 17,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: VerticalDivider(
                                      width: 0,
                                      color: aquaColors.surfaceBorderSecondary,
                                    ),
                                  ),
                                  AquaAssetIcon.fromAssetId(
                                    assetId: AssetIds.layer2,
                                    size: 17,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: VerticalDivider(
                                      width: 0,
                                      color: aquaColors.surfaceBorderSecondary,
                                    ),
                                  ),
                                  AquaAssetIcon.fromAssetId(
                                    assetId: AssetIds.btc,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: BuySellSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
