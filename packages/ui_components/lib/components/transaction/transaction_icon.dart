import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/components/icon/icon.dart';
import 'package:ui_components/config/config.dart';

class AquaTransactionIcon extends HookWidget {
  AquaTransactionIcon.send({
    super.key,
    this.size,
    this.colors,
    this.isFailed = false,
  }) : icon = AquaIcon.arrowUpRight(
          color: colors?.textSecondary,
          size: 18,
        );

  AquaTransactionIcon.receive({
    super.key,
    this.size,
    this.colors,
    this.isFailed = false,
  }) : icon = AquaIcon.arrowDownLeft(
          color: colors?.textSecondary,
          size: 18,
        );

  AquaTransactionIcon.swap({
    super.key,
    this.size,
    this.colors,
    this.isFailed = false,
  }) : icon = AquaIcon.swap(
          color: colors?.textSecondary,
          size: 18,
        );

  final Widget icon;
  final double? size;
  final AquaColors? colors;
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size ?? 40,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: colors?.surfaceSecondary,
              border: Border.all(
                color: colors?.surfaceBorderSecondary ?? Colors.transparent,
                width: 1,
              ),
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          if (isFailed) ...{
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors?.accentDanger,
                  shape: BoxShape.circle,
                ),
                child: AquaIcon.warning(
                  color: colors?.textInverse,
                  size: 16,
                ),
              ),
            ),
          },
        ],
      ),
    );
  }
}
