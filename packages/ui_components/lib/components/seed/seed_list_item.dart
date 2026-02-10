import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaSeedListItem extends StatelessWidget {
  const AquaSeedListItem({
    super.key,
    required this.index,
    required this.text,
    this.colors,
    this.showBackground = true,
  });

  final int index;
  final String text;
  final AquaColors? colors;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: showBackground ? colors?.surfacePrimary : null,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: AquaText.body2Medium(
              text: '$index',
              color: colors?.textTertiary,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 24),
          AquaText.body1Medium(text: text),
        ],
      ),
    );
  }
}
