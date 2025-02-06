import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';

class CategorizedAssetList extends HookConsumerWidget {
  const CategorizedAssetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Object>(
      reloadNotifier,
      (_, __) => ref.read(assetsProvider.notifier).reloadAssets(),
    );

    return ref.watch(assetsProvider).when(
          data: (assets) => Container(
            margin: const EdgeInsets.only(top: 262.0),
            child: AssetsList(assets: assets),
          ),
          loading: () => Container(
              margin: const EdgeInsets.only(top: 262.0),
              child: const AssetListSkeleton()),
          error: (error, _) => const AssetListErrorView(),
        );
  }
}
