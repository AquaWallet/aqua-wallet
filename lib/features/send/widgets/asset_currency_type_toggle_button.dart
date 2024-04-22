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
      dimension: 32.r,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(),
          child: Ink(
            width: 14.r,
            height: 14.r,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4.r),
              border: Theme.of(context).isLight
                  ? Border.all(
                      color: Theme.of(context).colors.divider,
                      width: 2.r,
                    )
                  : null,
            ),
            child: SvgPicture.asset(Svgs.walletExchange,
                fit: BoxFit.scaleDown,
                width: 14.r,
                height: 14.r,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onBackground,
                    BlendMode.srcIn)),
          ),
        ),
      ),
    );
  }
}
