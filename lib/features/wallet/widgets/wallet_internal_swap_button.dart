import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class WalletInternalSwapButton extends StatelessWidget {
  const WalletInternalSwapButton({
    super.key,
    this.isLoading = false,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: OutlinedButton(
        onPressed: !isLoading
            ? () => Navigator.of(context).pushNamed(SwapScreen.routeName)
            : null,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              Svgs.swap,
              width: 14.r,
              height: 14.r,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onBackground,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 7.w),
            Text(
              context.loc.convert,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 14.sp,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
