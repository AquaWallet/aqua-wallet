import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaNavHeader extends HookWidget {
  const AquaNavHeader({
    super.key,
    required this.title,
    this.onReceiveTap,
    this.onSendTap,
    this.onSwapTap,
    this.onMarketplaceTap,
    this.onRegionTap,
    this.onUserTap,
    this.onSettingsTap,
    this.colors,
  });

  final String title;
  final VoidCallback? onReceiveTap;
  final VoidCallback? onSendTap;
  final VoidCallback? onSwapTap;
  final VoidCallback? onMarketplaceTap;
  final VoidCallback? onRegionTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onSettingsTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    final isWideScreen = !context.isMobile && !context.isWideMobile;
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            AquaText.h4SemiBold(text: title),
            const Spacer(),
            AquaButton.utility(
              onPressed: onReceiveTap,
              icon: AquaIcon.arrowDownLeft(
                size: 18,
                color: colors?.textPrimary,
              ),
              text: !isWideScreen ? '' : 'Receive',
            ),
            const SizedBox(width: 16),
            AquaButton.utility(
              onPressed: onSendTap,
              icon: AquaIcon.arrowUpRight(
                size: 18,
                color: colors?.textPrimary,
              ),
              text: !isWideScreen ? '' : 'Send',
            ),
            const SizedBox(width: 16),
            AquaButton.utility(
              onPressed: onSwapTap,
              icon: AquaIcon.swap(
                size: 18,
                color: colors?.textPrimary,
              ),
              text: !isWideScreen ? '' : 'Swap',
            ),
            const SizedBox(width: 16),
            AquaButton.utility(
              onPressed: onMarketplaceTap,
              icon: AquaIcon.marketplace(
                size: 18,
                color: colors?.textPrimary,
              ),
              text: !isWideScreen ? '' : 'Marketplace',
            ),
            const SizedBox(width: 8),
            VerticalDivider(
              color: colors?.surfaceBorderSecondary,
              width: 20,
              thickness: 1,
            ),
            InkWell(
              onTap: onRegionTap,
              splashFactory: NoSplash.splashFactory,
              borderRadius: BorderRadius.circular(100),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const AquaText.h4SemiBold(
                  text: '🇳🇴',
                ),
              ),
            ),
            const SizedBox(width: 8),
            AquaIcon.user(
              onTap: onUserTap,
              color: colors?.textPrimary,
            ),
            const SizedBox(width: 8),
            AquaIcon.settings(
              onTap: onSettingsTap,
              color: colors?.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
