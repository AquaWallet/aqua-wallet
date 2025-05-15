import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaSeedListItem extends StatelessWidget {
  const AquaSeedListItem({
    super.key,
    required this.index,
    required this.text,
    this.colors,
  });

  final int index;
  final String text;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors?.surfacePrimary,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Row(
        children: [
          AquaText.body2Medium(
            text: '$index',
            color: colors?.textTertiary,
          ),
          const SizedBox(width: 24),
          AquaText.body1Medium(text: text),
        ],
      ),
    );
  }
}
