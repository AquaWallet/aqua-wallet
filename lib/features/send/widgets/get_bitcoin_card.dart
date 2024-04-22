import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

const iconsForUnit = {
  FeeAsset.lbtc: Svgs.liquidAsset,
  FeeAsset.tetherUsdt: Svgs.usdtAsset,
  FeeAsset.btc: Svgs.btcAsset,
};

const labelForUnit = {
  FeeAsset.lbtc: 'Liquid',
  FeeAsset.tetherUsdt: 'USDt',
  FeeAsset.btc: 'Bitcoin',
};

class GetBitcoinCard extends ConsumerWidget {
  const GetBitcoinCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeAsset = ref.read(userSelectedFeeAssetProvider);

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Ink(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                SizedBox(width: 14.w),
                SvgPicture.asset(
                  iconsForUnit[feeAsset]!,
                  width: 38.r,
                  height: 38.r,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.insufficientFundsSheetAssetTitle(
                            labelForUnit[feeAsset]!),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 18.sp,
                                ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        context.loc.insufficientFundsSheetAssetDescription,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontSize: 12.sp,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).isLight
                          ? Theme.of(context).colors.divider
                          : Colors.transparent,
                      width: 2.r,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    color: Theme.of(context).colorScheme.background,
                  ),
                  child: SvgPicture.asset(
                    Svgs.arrowForward,
                    width: 14.r,
                    height: 14.r,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onBackground,
                        BlendMode.srcIn),
                    fit: BoxFit.scaleDown,
                  ),
                ),
                SizedBox(width: 18.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
