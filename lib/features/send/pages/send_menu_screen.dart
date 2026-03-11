import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide AssetIds;

class SendMenuScreen extends HookConsumerWidget {
  const SendMenuScreen({super.key});

  static const routeName = '/sendMenu';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(sendMenuAssetsListProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    final onAssetSelected = useCallback((Asset asset) => context.push(
          SendAssetScreen.routeName,
          extra: SendAssetArguments.fromAsset(asset),
        ));

    ref.listen(selectedAssetProvider, (_, asset) {
      if (asset != null) {
        Future.microtask(() {
          onAssetSelected(asset);
        });
      }
    });

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.send,
        colors: context.aquaColors,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: AquaAssetSelector.send(
          assets:
              assets.withSelectorSubtitles(context, AquaAssetSelectorType.send),
          colors: context.aquaColors,
          type: AquaAssetSelectorType.send,
          selectedAssetId: selectedAsset?.id,
          onAssetSelected: ref.read(selectedAssetProvider.notifier).selectAsset,
          tapForOptionsText: context.loc.tapForOptions,
        ),
      ),
    );
  }
}
