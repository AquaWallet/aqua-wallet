import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletButton extends HookConsumerWidget {
  const WalletButton({
    super.key,
    required this.iconSvg,
    required this.title,
    required this.description,
    this.iconSize,
    this.paddingStart,
    this.paddingIcon,
    required this.onPressed,
  });

  final String iconSvg;
  final double? iconSize;
  final String title;
  final String description;
  final VoidCallback onPressed;
  final double? paddingStart;
  final double? paddingIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(lightThemeProvider(context));
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme,
      child: BoxShadowElevatedButton(
        onPressed: onPressed,
        background: colorScheme.background,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          height: 70.h,
          padding: EdgeInsets.only(
            left: paddingStart ?? 15.w,
            right: 10.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //ANCHOR - Icon
              SvgPicture.asset(
                iconSvg,
                width: iconSize ?? 40.r,
                height: iconSize ?? 40.r,
              ),
              SizedBox(width: paddingIcon ?? 17.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //ANCHOR - Title
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18.sp,
                            color: colorScheme.onBackground,
                            height: 1,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    //ANCHOR - Subtitle
                    Text(
                      description,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onBackground,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 18.w),
              //ANCHOR - Arrow
              SvgPicture.asset(
                Svgs.chevronRight,
                width: 12.r,
                height: 12.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
