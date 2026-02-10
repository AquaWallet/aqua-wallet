import 'package:flutter/material.dart';
import 'package:ui_components/config/theme_colors.dart';

class AquaDivider extends StatelessWidget {
  const AquaDivider({
    super.key,
    required this.colors,
  });

  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 1,
      color: colors.surfaceBackground,
    );
  }
}
