import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class AquaOutlinedButton extends StatelessWidget {
  const AquaOutlinedButton({
    super.key,
    this.onPressed,
    this.iconForegroundColor,
    this.iconBackgroundColor,
    this.child,
  });

  final VoidCallback? onPressed;
  final Color? iconForegroundColor;
  final Color? iconBackgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
          side: BorderSide(
            color: Theme.of(context).colors.roundedButtonOutlineColor,
            width: 2.w,
          ),
        ),
        foregroundColor:
            iconForegroundColor ?? Theme.of(context).colorScheme.onBackground,
        backgroundColor: iconBackgroundColor ??
            Theme.of(context).colors.walletTabButtonBackgroundColor,
      ),
      child: child,
    );
  }
}
