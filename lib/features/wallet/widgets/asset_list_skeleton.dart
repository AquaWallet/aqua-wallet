import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
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
          top: 304.h,
          bottom: 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Savings Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                text: AppLocalizations.of(context)!.tabSavings,
              ),
            ),
            SizedBox(height: 16.h),
            //ANCHOR - Savings List
            SkeletonAssetListItem(
              asset: Asset(
                id: 'btc',
                name: 'Bitcoin',
                ticker: 'BTC',
                logoUrl: '',
              ),
            ),
            SizedBox(height: 22.h),
            //ANCHOR - Spending Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                text: AppLocalizations.of(context)!.tabSpending,
                children: [
                  const Spacer(),
                  if (Platform.isAndroid) const WalletInternalSwapButton(),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            //ANCHOR - Spending List
            const SkeletonAssetListItem(),
            SizedBox(height: 14.h),
            const SkeletonAssetListItem(),
          ],
        ),
      ),
    );
  }
}

class SkeletonAssetListItem extends ConsumerWidget {
  const SkeletonAssetListItem({
    super.key,
    this.asset,
  });

  final Asset? asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Container(
        height: 100.h,
        padding: EdgeInsets.only(left: 16.w, right: 28.w),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          child: Row(
            children: [
              //ANCHOR - Icon
              Skeleton.keep(
                keep: asset != null,
                child: asset != null
                    ? AssetIcon(
                        assetId: asset!.id,
                        assetLogoUrl: asset!.logoUrl,
                        size: 54.r,
                      )
                    : Container(
                        width: 54.r,
                        height: 54.r,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(5.r)),
                        ),
                      ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //ANCHOR - Name
                    Skeleton.keep(
                      keep: asset?.name.isNotEmpty ?? false,
                      child: Text(
                        asset?.name ?? 'lorem ipsum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    //ANCHOR - Symbol
                    Skeleton.keep(
                      keep: asset?.name.isNotEmpty ?? false,
                      child: Text(
                        asset?.ticker ?? 'lorem ipsum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //ANCHOR - Amount
                  Text(
                    '12345678.90',
                    style: TextStyle(fontSize: 18.sp),
                  ),
                  //ANCHOR - USD Equivalent
                  Text(
                    '1234.56',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
