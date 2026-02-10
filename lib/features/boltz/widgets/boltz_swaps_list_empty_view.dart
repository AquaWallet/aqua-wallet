import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class BoltzSwapsListEmptyView extends StatelessWidget {
  const BoltzSwapsListEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        AquaRingedIcon(
          colors: context.aquaColors,
          variant: AquaRingedIconVariant.normal,
          icon: AquaIcon.swap(
            color: context.aquaColors.textTertiary,
          ),
        ),
        const SizedBox(height: 30.0),
        AquaText.h4Medium(
          text: context.loc.boltzSwapsListEmptyState,
          textAlign: TextAlign.center,
          color: context.aquaColors.textPrimary,
        ),
        const SizedBox(height: 12.0),
        AquaText.body1(
          text: context.loc.noBoltzSwapsFoundDescription,
          textAlign: TextAlign.center,
          color: context.aquaColors.textSecondary,
        ),
        const Spacer(flex: 5),
      ],
    );
  }
}
