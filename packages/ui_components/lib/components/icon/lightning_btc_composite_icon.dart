import 'package:flutter/material.dart';
import 'package:ui_components/gen/assets.gen.dart';

class LightningBtcCompositeIcon extends StatelessWidget {
  const LightningBtcCompositeIcon({
    super.key,
    this.size = 48.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.5;
    final mainIconSize = size;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Liquid Bitcoin base icon
        SizedBox(
          width: mainIconSize,
          height: mainIconSize,
          child: AquaUiAssets.svgs.currency.liquidBitcoin.svg(),
        ),
        // Lightning badge overlay
        Positioned(
          right: 0,
          bottom: 0,
          child: SizedBox(
            width: badgeSize,
            height: badgeSize,
            child: AquaUiAssets.svgs.currency.lightningBtc.svg(),
          ),
        ),
      ],
    );
  }
}
