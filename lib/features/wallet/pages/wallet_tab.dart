import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';

class WalletTab extends ConsumerWidget {
  const WalletTab({super.key});

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
      builder: (context, constraints) {
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
