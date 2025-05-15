import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaFloatingActionButton extends StatelessWidget {
  const AquaFloatingActionButton({
    super.key,
    this.onTap,
    required this.icon,
  });

  final AquaIconBuilder icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      shape: CircleBorder(
        side: BorderSide(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashFactory: InkSparkle.splashFactory,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          width: 64,
          height: 64,
          child: icon(
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }
}
