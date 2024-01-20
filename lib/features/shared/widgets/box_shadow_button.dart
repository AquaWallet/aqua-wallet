import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/shared/shared.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BoxShadowElevatedButton extends HookConsumerWidget {
  const BoxShadowElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.background,
    this.foreground,
    this.borderRadius,
    this.side,
    this.padding,
    this.elevation = 0,
  });

  factory BoxShadowElevatedButton.icon({
    required VoidCallback? onPressed,
    required Widget label,
    required Widget icon,
    Color? background,
    Color? foreground,
    BorderRadius? borderRadius,
    BorderSide? side,
    int? elevation,
    EdgeInsets? padding,
  }) {
    return BoxShadowElevatedButton(
      onPressed: onPressed,
      icon: icon,
      borderRadius: borderRadius,
      side: side,
      background: background,
      foreground: foreground,
      padding: padding,
      elevation: elevation ?? 0,
      child: label,
    );
  }

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Color? background;
  final Color? foreground;
  final BorderRadius? borderRadius;
  final BorderSide? side;
  final int elevation;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final style = useMemoized(
      () => ElevatedButton.styleFrom(
        elevation: 0,
        padding: padding,
        backgroundColor: background,
        foregroundColor: foreground,
        disabledForegroundColor: Theme.of(context).colorScheme.surface,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(.5),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12.r),
          side: side ?? BorderSide.none,
        ),
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
      [darkMode],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
        boxShadow: [Theme.of(context).shadow],
      ),
      child: icon == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: child,
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon!,
              label: child,
              style: style,
            ),
    );
  }
}
