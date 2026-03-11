import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class AltUsdtNetworkWarningChip extends StatelessWidget {
  const AltUsdtNetworkWarningChip({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return AquaChip.error(
      label: context.loc.onlyForInsertAltUsdtNetwork(asset.nameWithStandard),
      colors: context.aquaColors,
      compact: true,
    );
  }
}
