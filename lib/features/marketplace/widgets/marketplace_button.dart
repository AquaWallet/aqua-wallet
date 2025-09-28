import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/responsive_utils.dart';
import 'package:flutter_svg/svg.dart';

class MarketplaceButton extends HookConsumerWidget {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final bool isDisabled;

  const MarketplaceButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onPressed,
    this.onDisabledPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      borderRadius: BorderRadius.circular(12.0),
      color: Theme.of(context).colorScheme.onInverseSurface,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: InkWell(
          onTap: isDisabled ? onDisabledPressed : onPressed,
          borderRadius: BorderRadius.circular(12.0),
          child: Ink(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use a SizedBox with infinity width to ensure the Marketplace card takes full width if text isn't long enough
                const SizedBox(
                  width: double.infinity,
                  height: 0,
                ),
                //ANCHOR - Icon
                SizedBox.square(
                  dimension: context.adaptiveDouble(
                    smallMobile: 32.0,
                    mobile: 52.0,
                    wideMobile: 52.0,
                    tablet: 40.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Theme.of(context).colors.iconBackground,
                    ),
                    child: SvgPicture.asset(
                      icon,
                      height: 18.0,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colors.iconForeground,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
                SizedBox(
                    height:
                        context.adaptiveDouble(smallMobile: 32, mobile: 42)),
                //ANCHOR - Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: context.adaptiveDouble(
                          smallMobile: 14,
                          mobile: 16.0,
                          wideMobile: 14.0,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 7.0),
                //ANCHOR - Subtitle
                Expanded(
                  flex: 2,
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: context.adaptiveDouble(
                            mobile: 14.0,
                            wideMobile: 12.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
