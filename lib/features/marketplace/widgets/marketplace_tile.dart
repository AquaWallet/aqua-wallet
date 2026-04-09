import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/responsive_utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_components/components/surface/surface.dart';
import 'package:ui_components/components/text/text.dart';

class MarketplaceTile extends HookConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final String? icon;
  final Widget Function({Color? color, required double size})? iconBuilder;
  final bool isAuthRequired;
  final bool isDisabled;

  const MarketplaceTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onPressed,
    this.onDisabledPressed,
    this.icon,
    this.iconBuilder,
    this.isAuthRequired = false,
    this.isDisabled = false,
  }) : assert(
          (icon != null) != (iconBuilder != null),
          'Provide exactly one of: icon or iconBuilder.',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    final dimension = context.adaptiveDouble(
      smallMobile: 36.0,
      mobile: 52.0,
      wideMobile: 52.0,
      tablet: 40.0,
    );

    final iconSize = dimension * 0.45;

    final iconColor = useMemoized(
        () => isDisabled
            ? context.aquaColors.textSecondary.withOpacity(0.5)
            : context.aquaColors.textSecondary,
        [isDisabled, darkMode]);

    final Widget iconWidget = iconBuilder != null
        ? iconBuilder!(color: iconColor, size: iconSize)
        : SvgPicture.asset(
            icon!,
            height: iconSize,
            width: iconSize,
            fit: BoxFit.scaleDown,
            colorFilter: ColorFilter.mode(
                context.aquaColors.textSecondary, BlendMode.srcIn),
          );

    return AquaCard(
      onTap: isDisabled ? onDisabledPressed : onPressed,
      borderRadius: BorderRadius.circular(8),
      color: context.aquaColors.surfacePrimary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use a SizedBox with infinity width to ensure the Marketplace card takes full width if text isn't long enough
              const SizedBox(
                width: double.infinity,
                height: 0,
              ),
              //ANCHOR - Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: dimension,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40.0),
                        border: Border.all(
                            color: context.aquaColors.surfaceBorderSecondary),
                        color: context.aquaColors.surfaceSecondary,
                      ),
                      child: iconWidget,
                    ),
                  ),
                  if (isAuthRequired) ...[
                    SvgPicture.asset(
                      darkMode
                          ? UiAssets.svgs.dark.jan3MiniLogo.path
                          : UiAssets.svgs.light.jan3MiniLogo.path,
                      height: 24,
                      width: 24,
                    ),
                  ]
                ],
              ),
              SizedBox(
                  height: context.adaptiveDouble(smallMobile: 32, mobile: 42)),
              //ANCHOR - Title
              AquaText.body1SemiBold(
                text: title,
                size: 16,
              ),
              const SizedBox(height: 7.0),
              //ANCHOR - Subtitle
              AquaText.caption1Medium(
                text: subtitle,
                color: context.aquaColors.textSecondary,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
