import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:ui_components/ui_components.dart';

class WalletTab extends ConsumerWidget {
  const WalletTab({
    super.key,
    required this.refreshController,
  });

  final AquaRefreshController refreshController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listen<Object>(
        reloadNotifier,
        (_, __) => ref.read(assetsProvider.notifier).reloadAssets(),
      )
      ..listen(
        networkEventStreamProvider,
        (_, value) => value?.maybeWhen(
          data: (event) {
            if (event.any((e) => e == GdkNetworkEventStateEnum.connected)) {
              logger.debug('Reconnected - reloading assets');
              ref.read(assetsProvider.notifier).reloadAssets();
            }
          },
          orElse: () {},
        ),
      );

    return ref.watch(assetsProvider).when(
          data: (assets) => AssetsList(
            assets: assets,
            refreshController: refreshController,
          ),
          loading: () => AssetsList(
            assets: const [],
            refreshController: refreshController,
          ),
          error: (error, _) => const AssetListErrorView(),
        );
  }
}
