import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class AddAssetsScreen extends HookConsumerWidget {
  static const routeName = '/addAssetsScreen';

  const AddAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets =
        ref.watch(manageAssetsProvider.select((p) => p.availableAssets));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.addMoreAssets,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        itemCount: assets.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 10.0),
        itemBuilder: (_, index) => ManageAssetListItemTile(
          asset: assets[index],
          isUserAsset: false,
          onAdd: (asset) async => Future.microtask(() {
            ref.read(manageAssetsProvider).addAsset(asset);
          }),
        ),
      ),
    );
  }
}
