import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';
import 'package:aqua/config/config.dart';

class PokerchipScanViewButton extends StatelessWidget {
  const PokerchipScanViewButton({
    super.key,
    required this.iconSvg,
    required this.label,
    required this.onPressed,
  });

  final String iconSvg;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12.0),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: Ink(
          height: 52.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconSvg,
                width: 16.0,
                height: 16.0,
                fit: BoxFit.scaleDown,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colors.onBackground,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colors.onBackground,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
