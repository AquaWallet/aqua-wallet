import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class AquaOutlinedIconButton extends StatelessWidget {
  const AquaOutlinedIconButton({
    super.key,
    required this.child,
    required this.size,
    required this.onPressed,
  });

  final Widget child;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2.r,
            color: Theme.of(context).colors.divider,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
