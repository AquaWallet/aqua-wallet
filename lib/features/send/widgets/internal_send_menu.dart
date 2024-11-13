import 'package:aqua/config/config.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class InternalSendMenu extends HookConsumerWidget {
  const InternalSendMenu({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider).asData?.value ?? [];
    final btcAsset = useMemoized(
      () => assets.firstWhere((a) => a.isBTC),
      [assets],
    );
    final lbtcAsset = useMemoized(
      () => assets.firstWhere((a) => a.isLBTC),
      [assets],
    );
    final usdtAsset = useMemoized(
      () => assets.firstWhereOrNull((a) => a
          .isUsdtLiquid), // usdt can be null if removed from assets list by user
      [assets],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        //ANCHOR - Internal Swap Title
        Text(
          context.loc.internalSendTitle,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 22.sp,
                letterSpacing: .7,
              ),
        ),
        SizedBox(height: 16.h),
        //ANCHOR - Internal Swap Buttons
        if (asset.isBTC) ...{
          _InternalSendCard(
            deliverAsset: btcAsset,
            receiveAsset: lbtcAsset,
          ),
        },
        if (asset.isUsdtLiquid && usdtAsset != null) ...{
          _InternalSendCard(
            deliverAsset: usdtAsset,
            receiveAsset: lbtcAsset,
          ),
        },
        if (asset.isLBTC && usdtAsset != null) ...[
          _InternalSendCard(
            deliverAsset: lbtcAsset,
            receiveAsset: usdtAsset,
          ),
          SizedBox(height: 15.h),
        ],
        if (asset.isLBTC) ...{
          _InternalSendCard(
            deliverAsset: lbtcAsset,
            receiveAsset: btcAsset,
          ),
        },
      ],
    );
  }
}

class _InternalSendCard extends HookConsumerWidget {
  const _InternalSendCard({
    required this.deliverAsset,
    required this.receiveAsset,
  });

  final Asset deliverAsset;
  final Asset receiveAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10.r),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          //ANCHOR - Navigate to Internal Send screen
          onTap: () => Navigator.of(context).pushNamed(
            InternalSendAmountScreen.routeName,
            arguments: InternalSendArguments.amount(
              deliverAsset: deliverAsset,
              receiveAsset: receiveAsset,
            ),
          ),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 11.w,
              vertical: 8.h,
            ),
            child: Row(
              children: [
                //ANCHOR - Icon
                SizedBox.square(
                  dimension: 50.r,
                  child: receiveAsset.isLBTC
                      ? SvgPicture.asset(
                          Svgs.layerTwoSingle,
                          width: 50.r,
                          height: 50.r,
                        )
                      : AssetIcon(
                          assetId: receiveAsset.id,
                          assetLogoUrl: receiveAsset.logoUrl,
                          fit: BoxFit.contain,
                          size: 50.r,
                        ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //ANCHOR - Name
                    Text(
                      receiveAsset.isLBTC
                          ? context.loc.internalSendLbtcTitle
                          : receiveAsset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18.sp,
                            letterSpacing: 0.4,
                          ),
                    ),
                    //ANCHOR - Symbol
                    Text(
                      receiveAsset.isLBTC
                          ? context.loc.internalSendLbtcSubtitle
                          : receiveAsset.isUsdtLiquid
                              ? context.loc.internalSendUsdtSubtitle
                              : receiveAsset.ticker,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13.sp,
                            letterSpacing: 0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
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
