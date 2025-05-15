import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_components/gen/assets.gen.dart';

class AquaIndefinateProgressIndicator extends HookWidget {
  const AquaIndefinateProgressIndicator({
    super.key,
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    )..repeat();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) => Transform.rotate(
        angle: animationController.value * 2 * math.pi,
        child: SvgPicture.asset(
          AquaUiAssets.svgs.circularProgress.path,
          width: 24,
          height: 24,
          package: AquaUiAssets.package,
          colorFilter: color != null
              ? ColorFilter.mode(
                  color!,
                  BlendMode.srcIn,
                )
              : null,
        ),
      ),
    );
  }
}
