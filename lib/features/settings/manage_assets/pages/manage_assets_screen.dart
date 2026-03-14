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
    final discovered =
        ref.watch(manageAssetsProvider.select((p) => p.discoveredAssets));
    final enabledDiscovered =
        ref.watch(manageAssetsProvider.select((p) => p.enabledDiscoveredAssets));
    final items = useMemoized(() => assets, [assets.length]);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.manageAssets,
        colors: context.aquaColors,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: assets.isNotEmpty
                    ? SeparatedReorderableListView.separated(
                        itemCount: items.length,
                        physics: const NeverScrollableScrollPhysics(),
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
                            () async =>
                                ref.read(manageAssetsProvider).saveAssets(
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
                            title: asset.isLBTC
                                ? context.loc.layer2Bitcoin
                                : asset.name,
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
              if (discovered.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    context.loc.manageAssetsOtherAssets,
                    style: context.textTheme.titleMedium,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: discovered.map((asset) {
                      final isEnabled = enabledDiscovered.contains(asset);
                      return AquaListItem(
                        key: ValueKey('discovered_${asset.id}'),
                        title: asset.name,
                        subtitle: asset.ticker,
                        iconLeading: AquaAssetIcon.fromUrl(
                          url: asset.logoUrl,
                          size: 40,
                        ),
                        iconTrailing: AquaToggle(
                          value: isEnabled,
                          onChanged: (value) {
                            Future.microtask(
                              () {
                                if (isEnabled) {
                                  ref
                                      .read(manageAssetsProvider)
                                      .removeDiscoveredAsset(asset);
                                } else {
                                  ref
                                      .read(manageAssetsProvider)
                                      .addDiscoveredAsset(asset);
                                }
                              },
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
