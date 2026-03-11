import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

const kAppBarHeight = 60.0;

class AquaTopAppBar extends HookWidget implements PreferredSizeWidget {
  const AquaTopAppBar({
    super.key,
    this.title = '',
    this.showBackButton = true,
    this.onBackPressed,
    this.onTitlePressed,
    this.onTitleLongPressed,
    this.titleWidget,
    required this.colors,
    this.transparent = false,
    this.actions = const [],
  }) : assert(
          title == '' || titleWidget == null,
          'title and titleWidget cannot be used together',
        );

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onTitlePressed;
  final VoidCallback? onTitleLongPressed;
  final Widget? titleWidget;
  final AquaColors colors;
  final List<Widget> actions;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: BackdropFilter(
        filter: transparent
            ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
            : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: transparent
              ? Colors.transparent
              : colors.glassBackground.withOpacity(0.8),
          height: kAppBarHeight + padding.top,
          padding: EdgeInsets.only(
            top: padding.top + 16,
            bottom: 12,
            left: 12,
            right: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBackButton)
                AquaIcon.chevronLeft(
                  size: 24,
                  color: transparent ? colors.textInverse : colors.textPrimary,
                  onTap: () {
                    if (onBackPressed != null) {
                      onBackPressed?.call();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                )
              else
                const SizedBox(width: 24),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onTitlePressed,
                    onLongPress: onTitleLongPressed,
                    child:
                        titleWidget ?? AquaText.subtitleSemiBold(text: title),
                  ),
                ),
              ),
              if (actions.isEmpty) ...{
                const SizedBox(width: 24),
              },
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kAppBarHeight);
}

class AquaHeader extends HookWidget implements PreferredSizeWidget {
  const AquaHeader({
    super.key,
    this.showNotifications = false,
    this.refreshController,
    this.onRefresh,
    this.paddingTop,
    this.onWalletPressed,
    this.onNotificationsPressed,
    this.walletName,
    this.walletBalance,
    this.onBalanceVisibilityChanged,
    required this.isBalanceVisible,
    required this.colors,
    this.healthChecker,
  });

  final bool showNotifications;
  final double? paddingTop;
  final String? walletName;
  final String? walletBalance;
  final bool isBalanceVisible;
  final Function(bool visible)? onBalanceVisibilityChanged;
  final VoidCallback? onWalletPressed;
  final VoidCallback? onNotificationsPressed;
  final Widget? healthChecker;
  final AquaColors colors;
  final AquaRefreshController? refreshController;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    useListenable(refreshController);

    final shouldShowIndicator = refreshController?.isRefreshing ?? false;

    useEffect(() {
      if (onRefresh != null) {
        refreshController?.setOnRefresh(onRefresh!);
      }
      return null;
    }, [refreshController, onRefresh]);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: colors.glassBackground.withOpacity(0.8),
          padding: EdgeInsets.only(
            top: paddingTop ?? 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  AquaUiAssets.svgs.aquaLogo.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  healthChecker ?? const SizedBox.shrink(),
                  const Spacer(),
                  AquaVisibilityToggleButton(
                    size: 24,
                    isBalanceVisible: isBalanceVisible,
                    onBalanceVisibilityChanged: onBalanceVisibilityChanged,
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  if (showNotifications) ...{
                    AquaIcon.notification(
                      size: 24,
                      padding: const EdgeInsets.all(4),
                      onTap: onNotificationsPressed,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                  } else ...{
                    const SizedBox.square(dimension: 8),
                  },
                ],
              ),
              if (walletName != null) ...{
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: AquaWalletTile(
                    onWalletPressed: onWalletPressed,
                    walletName: walletName!,
                    isBalanceVisible: isBalanceVisible,
                    walletBalance: walletBalance,
                    colors: colors,
                  ),
                ),
              },
              AnimatedContainer(
                height: AquaLinearProgressIndicator.kMinHeight,
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedOpacity(
                  opacity: shouldShowIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: shouldShowIndicator
                      ? AquaLinearProgressFillIndicator(
                          colors: colors,
                          // If using controller, stop refresh when animation completes
                          onComplete: () => refreshController?.stopRefresh(),
                        )
                      : const SizedBox.shrink(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(166);
}
