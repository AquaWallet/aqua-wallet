import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';

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
            margin: EdgeInsets.only(
                top: context.adaptiveDouble(mobile: 262.0, smallMobile: 224.0)),
            child: AssetsList(assets: assets),
          ),
          loading: () => Container(
              margin: EdgeInsets.only(
                  top: context.adaptiveDouble(
                      mobile: 262.0, smallMobile: 202.0)),
              child: const AssetListSkeleton()),
          error: (error, _) => const AssetListErrorView(),
        );
  }
}
