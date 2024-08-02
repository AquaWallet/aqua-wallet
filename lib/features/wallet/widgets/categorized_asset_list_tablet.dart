import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';

class CategorizedAssetListTablet extends HookConsumerWidget {
  const CategorizedAssetListTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Object>(
      reloadNotifier,
      (_, __) => ref.read(assetsProvider.notifier).reloadAssets(),
    );

    return ref.watch(assetsProvider).when(
          data: (assets) => Container(
            margin: EdgeInsets.only(top: 270.h),
            child: AssetsList(assets: assets),
          ),
          loading: () => const AssetListSkeleton(),
          error: (error, _) => const AssetListErrorView(),
        );
  }
}
