import 'package:coin_cz/data/models/gdk_models.dart';
import 'package:coin_cz/data/provider/aqua_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/logger.dart';

class WalletTab extends ConsumerWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
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

    return LayoutBuilder(
      builder: (_, __) {
        return const Stack(
          children: [
            CategorizedAssetList(),
            WalletTabHeader(),
          ],
        );
      },
    );
  }
}
