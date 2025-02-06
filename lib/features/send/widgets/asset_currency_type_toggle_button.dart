import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class AssetCurrencyTypeToggleButton extends ConsumerWidget {
  const AssetCurrencyTypeToggleButton({
    super.key,
    required this.onTap,
  });

  final Function onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.square(
      dimension: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(),
          borderRadius: BorderRadius.circular(100),
          child: Ink(
            width: 14.0,
            height: 14.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Theme.of(context).isLight
                  ? Border.all(
                      color: Theme.of(context).colors.divider,
                      width: 2.0,
                    )
                  : null,
            ),
            child: SvgPicture.asset(Svgs.walletExchange,
                fit: BoxFit.scaleDown,
                width: 14.0,
                height: 14.0,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colors.onBackground, BlendMode.srcIn)),
          ),
        ),
      ),
    );
  }
}
