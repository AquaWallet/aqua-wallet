import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AquaAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const AquaAppBar({
    super.key,
    this.title = '',
    this.showBackButton = true,
    this.showActionButton = true,
    this.actionButtonAsset,
    this.actionButtonIconSize,
    this.backgroundColor,
    this.foregroundColor,
    this.iconBackgroundColor,
    this.iconForegroundColor,
    this.iconOutlineColor,
    this.elevated = false,
    this.onBackPressed,
    this.onActionButtonPressed,
    this.onTitlePressed,
  });

  final String title;
  final bool showBackButton;
  final bool showActionButton;
  final String? actionButtonAsset;
  final double? actionButtonIconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? iconBackgroundColor;
  final Color? iconForegroundColor;
  final Color? iconOutlineColor;
  final bool elevated;
  final VoidCallback? onBackPressed;
  final VoidCallback? onActionButtonPressed;
  final VoidCallback? onTitlePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final darkTheme = useMemoized(() => ref.read(darkThemeProvider(context)));
    final lightTheme = useMemoized(() => ref.read(lightThemeProvider(context)));
    final theme = useMemoized(
      () => darkMode ? darkTheme : lightTheme,
      [darkMode],
    );
    final defaultIconForegroundColor = useMemoized(
      () => theme.colorScheme.onBackground,
      [darkMode],
    );
    final defaultIconBackgroundColor = useMemoized(
      () => theme.colorScheme.surface,
      [darkMode],
    );
    final defaultIconOutlineColor = useMemoized(
      () => theme.colors.appBarIconOutlineColor,
      [darkMode],
    );

    return AppBar(
      centerTitle: true,
      toolbarHeight: kToolbarHeight,
      title: GestureDetector(
        onTap: onTitlePressed,
        child: Text(
          title,
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                color: foregroundColor,
              ),
        ),
      ),
      automaticallyImplyLeading: false,
      leadingWidth: 96.w,
      backgroundColor: backgroundColor,
      leading: !showBackButton
          ? const SizedBox.shrink()
          : Center(
              child: AppbarButton(
                svgAssetName: Svgs.backButton,
                elevated: darkMode && elevated,
                outlineColor: iconOutlineColor ?? defaultIconOutlineColor,
                foreground: iconForegroundColor ?? defaultIconForegroundColor,
                background: iconBackgroundColor ?? defaultIconBackgroundColor,
                onPressed: () {
                  onBackPressed?.call();
                  Navigator.of(context).maybePop();
                },
              ),
            ),
      actions: showActionButton
          ? [
              Center(
                child: actionButtonAsset == null ||
                        (actionButtonAsset?.contains('assets/') ?? false)
                    ? AppbarButton(
                        onPressed: onActionButtonPressed ?? () {},
                        elevated: darkMode && elevated,
                        svgAssetName: actionButtonAsset ?? Svgs.support,
                        outlineColor:
                            iconOutlineColor ?? defaultIconOutlineColor,
                        foreground:
                            iconForegroundColor ?? defaultIconForegroundColor,
                        background:
                            iconBackgroundColor ?? defaultIconBackgroundColor,
                      )
                    : SizedBox.square(
                        dimension: 40.w,
                        child: AquaOutlinedButton(
                          onPressed: onActionButtonPressed ?? () {},
                          iconBackgroundColor:
                              iconBackgroundColor ?? defaultIconBackgroundColor,
                          child: CountryFlag.fromCountryCode(
                            actionButtonAsset!,
                            width: 20.r,
                            height: 20.r,
                            borderRadius: 5.r,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 28.w),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
