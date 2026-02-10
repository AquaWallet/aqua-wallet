import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ManageAssetsScreen extends HookConsumerWidget {
  static const routeName = '/manageAssetsScreen';

  const ManageAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(manageAssetsProvider.select((p) => p.allAssets));
    final userAssets =
        ref.watch(manageAssetsProvider.select((p) => p.userAssets));
    final items = useMemoized(() => assets, [assets.length]);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.manageAssets,
        colors: context.aquaColors,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: assets.isNotEmpty
              ? SeparatedReorderableListView.separated(
                  itemCount: items.length,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  handleOnlyMode: true,
                  onReorder: (oldIndex, newIndex) {
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);

                    // Only save the order of enabled assets
                    final enabledAssets = items
                        .where((asset) => userAssets.contains(asset))
                        .toList();
                    Future.microtask(
                      () async => ref.read(manageAssetsProvider).saveAssets(
                            enabledAssets,
                          ),
                    );
                  },
                  proxyDecorator: (child, index, _) => Card(
                    elevation: 8.0,
                    child: child,
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 1),
                  itemBuilder: (_, index) {
                    final asset = items[index];
                    return AquaListItem(
                      key: ValueKey(asset),
                      title:
                          asset.isLBTC ? context.loc.layer2Bitcoin : asset.name,
                      iconLeading: asset.isLBTC
                          ? AquaAssetIcon.l2Bitcoin(
                              size: 40,
                            )
                          : AquaAssetIcon.fromUrl(
                              url: asset.logoUrl,
                              size: 40,
                            ),
                      iconTrailing: Row(
                        children: [
                          if (asset.isRemovable)
                            AquaToggle(
                              value: userAssets.contains(asset),
                              onChanged: (value) {
                                Future.microtask(
                                  () {
                                    if (userAssets.contains(asset)) {
                                      ref
                                          .read(manageAssetsProvider)
                                          .removeAsset(asset);
                                    } else {
                                      ref
                                          .read(manageAssetsProvider)
                                          .addAsset(asset);
                                    }
                                  },
                                );
                              },
                            ),
                          const SizedBox(width: 16),
                          SeparatedReorderableListView.buildDragHandle(
                            index: index,
                            child: AquaIcon.grab(
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : AssetListErrorView(
                  message: context.loc.manageAssetsScreenError,
                ),
        ),
      ),
    );
  }
}
