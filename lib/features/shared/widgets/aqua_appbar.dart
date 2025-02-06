import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/keys/shared_keys.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const kAppBarHeight = 66.0;

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
    this.shouldPopOnCustomBack = true,
    this.onBackPressed,
    this.onActionButtonPressed,
    this.onTitlePressed,
    this.titleWidget,
  }) : assert(
          title == '' || titleWidget == null,
          'title and titleWidget cannot be used together',
        );

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
  final bool shouldPopOnCustomBack;
  final VoidCallback? onBackPressed;
  final VoidCallback? onActionButtonPressed;
  final VoidCallback? onTitlePressed;
  final Widget? titleWidget;

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
      () => theme.colors.onBackground,
      [darkMode],
    );
    final foregroundColor = useMemoized(
      () => theme.colors.onBackground,
      [darkMode],
    );
    final defaultIconBackgroundColor = useMemoized(
      () => theme.colors.addressFieldContainerBackgroundColor,
      [darkMode],
    );
    final defaultIconOutlineColor = useMemoized(
      () => theme.colors.appBarIconOutlineColor,
      [darkMode],
    );

    return AppBar(
      centerTitle: true,
      toolbarHeight: kAppBarHeight,
      titleTextStyle: TextStyle(
        color: foregroundColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: UiFontFamily.helveticaNeue,
      ),
      title: GestureDetector(
        onTap: onTitlePressed,
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          child: titleWidget ?? Text(title),
        ),
      ),
      automaticallyImplyLeading: false,
      leadingWidth: 96.0,
      backgroundColor: backgroundColor ?? theme.colors.background,
      leading: !showBackButton
          ? const SizedBox.shrink()
          : Center(
              child: AppbarButton(
                key: SharedScreenKeys.sharedBackButton,
                svgAssetName: Svgs.backButton,
                elevated: darkMode && elevated,
                outlineColor: iconOutlineColor ?? defaultIconOutlineColor,
                foreground: iconForegroundColor ?? defaultIconForegroundColor,
                background: iconBackgroundColor ?? defaultIconBackgroundColor,
                onPressed: () {
                  onBackPressed?.call();
                  if (shouldPopOnCustomBack) {
                    context.maybePop();
                  }
                },
              ),
            ),
      actions: showActionButton
          ? [
              Center(
                child: actionButtonAsset == null ||
                        !(actionButtonAsset?.contains('flags/') ?? false)
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
                        dimension: context.adaptiveDouble(
                            smallMobile: 36, mobile: 40.0),
                        child: AquaOutlinedButton(
                          onPressed: onActionButtonPressed ?? () {},
                          iconBackgroundColor:
                              iconBackgroundColor ?? defaultIconBackgroundColor,
                          child: CountryFlag(
                            svgAsset: actionButtonAsset!,
                            width: 20.0,
                            height: 20.0,
                            borderRadius: 5.0,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 28.0),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kAppBarHeight);
}
