import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

class WalletInternalSwapButton extends StatelessWidget {
  const WalletInternalSwapButton({
    super.key,
    this.isLoading = false,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 33.h,
      child: OutlinedButton(
        onPressed: !isLoading
            ? () => Navigator.of(context).pushNamed(SwapScreen.routeName)
            : null,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 9.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
          side: BorderSide(
            color: context.colors.swapButtonForeground,
            width: 1.r,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Let the Row take up only the space needed
          children: [
            SizedBox(width: 1.w),
            UiAssets.svgs.assetHeaderSwap.svg(
              width: 10.w,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                context.colors.swapButtonForeground,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 9.w),
            Text(
              context.loc.convert,
              style: TextStyle(
                fontSize: 14.sp,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
                color: context.colors.swapButtonForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
