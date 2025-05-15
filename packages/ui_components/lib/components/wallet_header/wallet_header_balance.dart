import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

const kBalanceHidden = '✱✱✱✱';

class AquaWalletHeaderBalance extends HookWidget {
  const AquaWalletHeaderBalance({
    super.key,
    required this.colors,
    required this.currencySymbol,
    required this.balance,
    required this.onBalanceVisibleChanged,
    this.isNegative = false,
    this.isBalanceVisible = true,
    this.trendPercent,
    this.trendAmount,
  });

  final String currencySymbol;
  final String balance;
  final bool isNegative;
  final String? trendPercent;
  final String? trendAmount;
  final bool isBalanceVisible;
  final Function(bool visible) onBalanceVisibleChanged;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AquaText.body2SemiBold(
              text: context.loc.totalBalance,
              color: colors?.textSecondary,
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => onBalanceVisibleChanged(!isBalanceVisible),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isBalanceVisible
                    ? AquaIcon.eyeOpen(
                        color: colors?.textPrimary,
                        size: 16,
                      )
                    : AquaIcon.eyeClose(
                        color: colors?.textPrimary,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isBalanceVisible ? 1.0 : 0.0,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: currencySymbol,
                      style: AquaTypography.h5SemiBold.copyWith(
                        color: colors?.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: balance,
                      style: AquaTypography.h5SemiBold,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isBalanceVisible ? 0.0 : 1.0,
              child: AquaText.h5SemiBold(
                text: kBalanceHidden,
                color: colors?.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
