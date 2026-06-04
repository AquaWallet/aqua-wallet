import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaGlassButton extends StatelessWidget {
  const AquaGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final AquaIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48.0,
      child: ClipOval(
        child: Material(
          color: AquaColors.lightColors.glassSurface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
