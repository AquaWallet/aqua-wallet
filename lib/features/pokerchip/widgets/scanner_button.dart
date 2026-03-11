import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class ScannerButton extends StatelessWidget {
  const ScannerButton({super.key, required this.onTap, required this.icon});

  final VoidCallback onTap;
  final AquaIcon icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48.0,
      child: ClipOval(
        child: Material(
          color: context.aquaColors.glassSurface,
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
