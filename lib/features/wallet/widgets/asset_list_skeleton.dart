import 'dart:io';

import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetListSkeleton extends ConsumerWidget {
  const AssetListSkeleton({super.key});

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
      child: Container(
        padding: const EdgeInsets.only(
          left: 28.0,
          right: 28.0,
          bottom: 80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            //ANCHOR - Savings Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                  text: context.loc.tabSavings,
                  children: const [
                    Spacer(),
                    SizedBox(height: 33),
                  ]),
            ),
            const SizedBox(height: 18),
            //ANCHOR - Savings List
            SkeletonAssetListItem(
              asset: Asset(
                id: 'btc',
                name: 'Bitcoin',
                ticker: 'BTC',
                logoUrl: '',
              ),
            ),
            const SizedBox(height: 18),
            //ANCHOR - Spending Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                text: context.loc.tabSpending,
                children: [
                  const Spacer(),
                  if (!(Platform.isIOS && disableSideswapOnIOS))
                    const SizedBox(
                        height:
                            33), // Swap button is hidden until balance is shown
                ],
              ),
            ),
            const SizedBox(height: 18.0),
            //ANCHOR - Spending List
            const SkeletonAssetListItem(),
            const SizedBox(height: 14.0),
            const SkeletonAssetListItem(
              ticker: '1234567',
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonAssetListItem extends HookConsumerWidget {
  const SkeletonAssetListItem({
    super.key,
    this.asset,
    this.ticker,
  });

  final Asset? asset;
  final String? ticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final subtitleTextStyle = useMemoized(
      () => TextStyle(
        height: 1,
        letterSpacing: 0,
        wordSpacing: 1,
        fontWeight: FontWeight.w500,
        color: context.colorScheme.onSurface,
        fontSize: context.adaptiveDouble(
          mobile: 14.0,
          wideMobile: 10.0,
        ),
      ),
      [context.mounted],
    );

    return BoxShadowCard(
      bordered: !darkMode,
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(9.0),
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Container(
        height: 96.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(9.0),
          child: Container(
            padding: const EdgeInsets.only(top: 1.0),
            child: Row(
              children: [
                //ANCHOR - Icon
                Skeleton.keep(
                  keep: asset != null,
                  child: asset != null
                      ? AssetIcon(
                          assetId: asset!.id,
                          assetLogoUrl: asset!.logoUrl,
                          size: 50.0,
                        )
                      : const Bone.square(
                          size: 50.0,
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                ),
                SizedBox(
                  width: asset?.id == 'btc' ? 16.0 : 8.0,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 1.0),
                      //ANCHOR - Name
                      Skeleton.keep(
                        keep: asset?.name.isNotEmpty ?? false,
                        child: Text(
                          asset?.name ?? 'Layer 2 Bitcoin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            letterSpacing: 0,
                            wordSpacing: 1.7,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            fontSize: context.adaptiveDouble(
                              mobile: 18.0,
                              wideMobile: 14.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: asset?.isBTC ?? false ? 10.0 : 2.0),
                      //ANCHOR - Symbol
                      Skeleton.keep(
                        keep: asset?.name.isNotEmpty ?? false,
                        child: Text(
                          ticker ?? asset?.ticker ?? 'Liquid & Lightning',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleTextStyle,
                        ),
                      ),
                      SizedBox(height: asset?.id == 'btc' ? 2.0 : 5.0),
                    ],
                  ),
                ),
                const SizedBox(width: 18.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //ANCHOR - Amount
                    Text(
                      '1234567899',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.adaptiveDouble(
                          mobile: 16.0,
                          wideMobile: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    //ANCHOR - USD Equivalent
                    Text(
                      '1234.5678',
                      style: subtitleTextStyle,
                    ),
                    const SizedBox(height: 5.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
