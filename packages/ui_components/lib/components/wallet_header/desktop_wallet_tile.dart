import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

const kBalanceHidden = '✱✱✱✱✱✱';

class AquaDesktopWalletTile extends HookWidget {
  const AquaDesktopWalletTile({
    super.key,
    required this.colors,
    required this.walletName,
    this.isBalanceVisible = true,
    this.isCached = false,
    this.walletBalance,
    this.symbol,
    this.padding,
  });

  final String walletName;
  final String? walletBalance;
  final String? symbol;
  final bool isBalanceVisible;
  final bool isCached;
  final EdgeInsets? padding;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    final isBalanceVisible = useState(this.isBalanceVisible);

    return AquaCard.glass(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: padding ??
            const EdgeInsets.symmetric(
              vertical: 32,
              horizontal: 24,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AquaIcon.wallet(
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AquaText.body1SemiBold(
                    text: walletName,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Stack(
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isBalanceVisible.value ? 1.0 : 0.0,
                      child: Row(
                        children: [
                          Opacity(
                            opacity: isCached ? 0.5 : 1,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: symbol,
                                    style: AquaTypography.h4SemiBold.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: walletBalance,
                                    style: AquaTypography.h4SemiBold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          AquaVisibilityToggleButton(
                            isBalanceVisible: isBalanceVisible.value,
                            onBalanceVisibilityChanged: (value) =>
                                isBalanceVisible.value = value,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isBalanceVisible.value ? 0.0 : 1.0,
                      child: Row(
                        children: [
                          AquaText.h4SemiBold(
                            text: kBalanceHidden,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          AquaVisibilityToggleButton(
                            isBalanceVisible: isBalanceVisible.value,
                            onBalanceVisibilityChanged: (value) =>
                                isBalanceVisible.value = value,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
