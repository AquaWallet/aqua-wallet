import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class UnitCurrencyChip extends StatelessWidget {
  const UnitCurrencyChip({
    super.key,
    required this.asset,
    required this.rate,
    required this.unit,
    required this.showUnit,
  });

  final Asset asset;
  final ExchangeRate rate;
  final AquaAssetInputUnit unit;
  final bool showUnit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      elevation: 8,
      shadowColor: Colors.black26,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showUnit) ...[
              AquaText.body2SemiBold(
                text: unit == AquaAssetInputUnit.crypto
                    ? asset.ticker
                    : asset.getDisplayTicker(
                        SupportedDisplayUnits.fromAssetInputUnit(unit),
                      ),
              ),
              AquaText.body2(
                text: ' | ',
                color: context.aquaColors.surfaceBorderSecondary,
              ),
            ],
            Row(
              children: [
                CountryFlag(
                  svgAsset: rate.currency.format.flagSvg,
                  size: 16,
                ),
                const SizedBox(width: 4),
                AquaText.body2SemiBold(
                  text: rate.shortName(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
