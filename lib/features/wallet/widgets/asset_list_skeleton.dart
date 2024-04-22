import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
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
            SizedBox(height: 18.h),
            //ANCHOR - Spending Header
            Skeleton.keep(
              child: AssetListSectionHeader(
                text: context.loc.tabSpending,
                children: const [
                  Spacer(),
                  WalletInternalSwapButton(),
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

class SkeletonAssetListItem extends ConsumerWidget {
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

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Container(
        height: 100.5.h,
        padding: EdgeInsets.only(
          left: 16.w,
          right: 20.w,
        ),
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
                    : Bone.square(
                        size: 54.r,
                        borderRadius: BorderRadius.all(Radius.circular(5.r)),
                      ),
              ),
              SizedBox(
                width: asset?.id == 'btc' ? 14.w : 8.w,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 1.25.h),
                    //ANCHOR - Name
                    Skeleton.keep(
                      keep: asset?.name.isNotEmpty ?? false,
                      child: Text(
                        asset?.name ?? 'Layer 2 Bitcoin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: context.adaptiveDouble(
                                  mobile: asset?.id == 'btc' ? 18.sp : 20.sp,
                                  wideMobile: 18.sp),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(height: asset?.id == 'btc' ? 5.5.h : 2.h),
                    //ANCHOR - Symbol
                    Skeleton.keep(
                      keep: asset?.name.isNotEmpty ?? false,
                      child: Text(
                        ticker ?? asset?.ticker ?? 'Liquid & Lightning',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: asset?.id == 'btc' ? 14.sp : 17.sp,
                            ),
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
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(height: 2.h),
                  //ANCHOR - USD Equivalent
                  Text(
                    '1234.5678',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 17.sp,
                        ),
                  ),
                  SizedBox(height: 5.h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
