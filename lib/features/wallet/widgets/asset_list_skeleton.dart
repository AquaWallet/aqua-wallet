import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetListSkeleton extends ConsumerWidget {
  const AssetListSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    return Skeletonizer(
      effect: darkMode
          ? ShimmerEffect(
              baseColor: Theme.of(context).colorScheme.background,
              highlightColor: Theme.of(context).colorScheme.surface,
            )
          : const ShimmerEffect(),
      child: Container(
        padding: EdgeInsets.only(
          left: 28.w,
          right: 28.w,
          top: 305.5.h,
          bottom: 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Savings Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                text: context.loc.tabSavings,
              ),
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Savings List
            SkeletonAssetListItem(
              asset: Asset(
                id: 'btc',
                name: 'Bitcoin',
                ticker: 'BTC',
                logoUrl: '',
              ),
            ),
            SizedBox(height: 16.h),
            //ANCHOR - Spending Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                text: context.loc.tabSpending,
                children: [
                  const Spacer(),
                  if (!(Platform.isIOS && disableSideswapOnIOS))
                    const WalletInternalSwapButton(),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Spending List
            const SkeletonAssetListItem(),
            SizedBox(height: 14.h),
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
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final subtitleTextStyle = useMemoized(
      () => TextStyle(
        height: 1,
        letterSpacing: 0,
        wordSpacing: 1,
        fontWeight: FontWeight.w500,
        color: context.colorScheme.onSurface,
        fontSize: context.adaptiveDouble(
          mobile: 14.sp,
          wideMobile: 10.sp,
        ),
      ),
      [context.mounted],
    );

    return BoxShadowCard(
      bordered: !darkMode,
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(9.r),
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Container(
        height: 96.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(9.r),
          child: Container(
            padding: EdgeInsets.only(top: 1.h),
            child: Row(
              children: [
                //ANCHOR - Icon
                Skeleton.keep(
                  keep: asset != null,
                  child: asset != null
                      ? AssetIcon(
                          assetId: asset!.id,
                          assetLogoUrl: asset!.logoUrl,
                          size: 50.r,
                        )
                      : Bone.square(
                          size: 50.r,
                          borderRadius: BorderRadius.all(Radius.circular(5.r)),
                        ),
                ),
                SizedBox(
                  width: asset?.id == 'btc' ? 16.w : 8.w,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1.h),
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
                              mobile: 18.sp,
                              wideMobile: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: asset?.isBTC ?? false ? 10.h : 2.h),
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
                      SizedBox(height: asset?.id == 'btc' ? 2.h : 5.h),
                    ],
                  ),
                ),
                SizedBox(width: 18.w),
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
                          mobile: 16.sp,
                          wideMobile: 10.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    //ANCHOR - USD Equivalent
                    Text(
                      '1234.5678',
                      style: subtitleTextStyle,
                    ),
                    SizedBox(height: 5.h),
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
