import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';

class WalletTab extends ConsumerWidget {
  const WalletTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      networkEventStreamProvider,
      (_, value) => value?.maybeWhen(
        data: (event) {
          if (event.any((e) => e == GdkNetworkEventStateEnum.connected)) {
            logger.d('Reconnected - reloading assets');
            ref.read(assetsProvider.notifier).reloadAssets();
          }
        },
        orElse: () {},
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double screenWidth = constraints.maxWidth;
        DeviceCategory deviceCategory =
            ResponsiveBreakpoints.getDeviceCategory(screenWidth);

        return deviceCategory == DeviceCategory.tabletPortrait
            ? const _TabletLayout()
            : const _MobileLayout();
      },
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Stack(
      children: [
        CategorizedAssetList(),
        WalletTabHeader(),
      ],
    );
  }
}

class _TabletLayout extends ConsumerWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Stack(
      children: [
        CategorizedAssetListTablet(),
        WalletTabHeaderTablet(),
      ],
    );
  }
}
