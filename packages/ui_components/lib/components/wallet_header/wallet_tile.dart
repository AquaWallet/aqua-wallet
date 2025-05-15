import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaWalletTile extends StatelessWidget {
  const AquaWalletTile({
    super.key,
    required this.onWalletPressed,
    required this.colors,
    required this.walletName,
    this.nameSpacing = 8,
    this.walletBalance,
    this.padding,
    this.isSolid = true,
  });

  final String walletName;
  final String? walletBalance;
  final VoidCallback? onWalletPressed;
  final double nameSpacing;
  final EdgeInsets? padding;
  final bool isSolid;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return AquaCard.glass(
      onTap: onWalletPressed,
      color: isSolid ? null : colors.surfaceBackground.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: padding ??
            const EdgeInsets.only(
              top: 8,
              bottom: 8,
              left: 16,
              right: 8,
            ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AquaIcon.wallet(
              size: 24,
              color: isSolid ? colors.textPrimary : colors.textInverse,
            ),
            SizedBox(width: nameSpacing),
            Expanded(
              child: AquaText.body1SemiBold(
                text: walletName,
                color: isSolid ? colors.textPrimary : colors.textInverse,
              ),
            ),
            AquaText.body2SemiBold(
              text: walletBalance ?? '',
              color: isSolid ? colors.textPrimary : colors.textInverse,
            ),
            const SizedBox(width: 8),
            AquaIcon.chevronRight(
              size: 18,
              color: isSolid ? colors.textPrimary : colors.textInverse,
            ),
          ],
        ),
      ),
    );
  }
}
