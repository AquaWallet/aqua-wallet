import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

const _kHiddenBalancePlaceholder = '✱✱✱✱';

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
    this.isBalanceVisible = true,
    this.isShowingFingerprint = false,
    this.fingerprint,
  }) : assert(
          !isShowingFingerprint ||
              (isShowingFingerprint && fingerprint != null),
          'fingerprint must be provided if isShowingFingerprint is true',
        );

  final String walletName;
  final String? walletBalance;
  final VoidCallback? onWalletPressed;
  final double nameSpacing;
  final EdgeInsets? padding;
  final bool isSolid;
  final bool isBalanceVisible;
  final AquaColors colors;
  final bool isShowingFingerprint;
  final String? fingerprint;

  @override
  Widget build(BuildContext context) {
    return AquaCard.glass(
      onTap: onWalletPressed,
      color: isSolid
          ? colors.surfacePrimary
          : colors.surfaceBackground.withOpacity(0.12),
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
            isShowingFingerprint
                ? AquaText.body2SemiBold(
                    text: fingerprint ?? '',
                    color: isSolid ? colors.textSecondary : colors.textInverse,
                  )
                : Opacity(
                    opacity: isBalanceVisible ? 1 : 0.5,
                    child: AquaText.body2SemiBold(
                      text: isBalanceVisible
                          ? walletBalance ?? ''
                          : _kHiddenBalancePlaceholder,
                      color:
                          isSolid ? colors.textSecondary : colors.textInverse,
                    ),
                  ),
            const SizedBox(width: 8),
            AquaIcon.chevronRight(
              size: 18,
              color: isSolid ? colors.textTertiary : colors.textInverse,
            ),
          ],
        ),
      ),
    );
  }
}
