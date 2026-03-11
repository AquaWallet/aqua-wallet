import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SendSelectorSideSheet extends HookWidget {
  const SendSelectorSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final selectedAssetId = useState<String?>(null);
    final assetsWithSubtitles = receiveAssets.withSelectorSubtitles(
      context,
      AquaAssetSelectorType.send,
    );
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.send,
      showBackButton: false,
      children: [
        AquaAssetSelector.receive(
          assets: assetsWithSubtitles,
          selectedAssetId: selectedAssetId.value,
          colors: aquaColors,
          tapForOptionsText: loc.tapForOptions,
          onAssetSelected: (assetId) {
            debugPrint(assetId);
            if (assetId == null) return;
            if (selectedAssetId.value == assetId) {
              selectedAssetId.value = null;
            } else {
              if (assetId != AssetIds.usdtTether) {
                SendFlowSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                  assetId: assetId,
                );
              }
              selectedAssetId.value = assetId;
            }
          },
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: SendSelectorSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
