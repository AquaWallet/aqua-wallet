import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/settings/manage_assets/keys/manage_assets_screen_keys.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ManageAssetsScreen extends HookConsumerWidget {
  static const routeName = '/manageAssetsScreen';

  const ManageAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(manageAssetsProvider.select((p) => p.userAssets));
    final items = useMemoized(() => assets, [assets.length]);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.manageAssets,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          children: [
            Expanded(
              child: assets.isNotEmpty
                  ? SeparatedReorderableListView.separated(
                      itemCount: items.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      onReorder: (oldIndex, newIndex) {
                        final item = items.removeAt(oldIndex);
                        items.insert(newIndex, item);
                        Future.microtask(() async =>
                            ref.read(manageAssetsProvider).saveAssets(items));
                      },
                      proxyDecorator: (child, index, _) => Card(
                        elevation: 8.0,
                        child: child,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                      itemBuilder: (_, index) {
                        final asset = items[index];
                        return ManageAssetListItemTile(
                          key: ValueKey(asset),
                          asset: asset,
                          isUserAsset: true,
                          onRemove: (asset) async => Future.microtask(() {
                            ref.read(manageAssetsProvider).removeAsset(asset);
                          }),
                        );
                      },
                    )
                  : AssetListErrorView(
                      message: context.loc.manageAssetsScreenError,
                    ),
            ),
            SizedBox(
              key: ManageAssetsScreenKeys.manageAssetAddAssetButton,
              width: double.maxFinite,
              child: BoxShadowElevatedButton(
                onPressed: assets.isEmpty
                    ? null
                    : () => context.push(AddAssetsScreen.routeName),
                child: Text(
                  context.loc.addMoreAssets,
                ),
              ),
            ),
            const SizedBox(height: kBottomPadding),
          ],
        ),
      ),
    );
  }
}
