import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';

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
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(
            color: Theme.of(context).colors.roundedButtonOutlineColor,
            width: 2.0,
          ),
        ),
        foregroundColor:
            iconForegroundColor ?? Theme.of(context).colors.onBackground,
        backgroundColor: iconBackgroundColor ??
            Theme.of(context).colors.walletTabButtonBackgroundColor,
      ),
      child: child,
    );
  }
}
