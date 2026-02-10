import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SkeletonAssetListItem extends HookConsumerWidget {
  const SkeletonAssetListItem({
    super.key,
    this.assets,
    this.ticker,
  });

  final List<Asset>? assets;
  final String? ticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return Skeletonizer(
      effect: darkMode
          ? ShimmerEffect(
              baseColor: Theme.of(context).colors.background,
              highlightColor: Theme.of(context).colorScheme.surface,
            )
          : const ShimmerEffect(),
      child: SectionAssetList(
        items: assets ?? [Asset.btc()],
      ),
    );
  }
}
