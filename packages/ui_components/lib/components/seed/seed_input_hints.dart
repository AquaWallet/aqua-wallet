import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaSeedInputHints extends StatelessWidget {
  const AquaSeedInputHints({
    super.key,
    required this.hints,
    required this.onHintSelected,
    this.colors,
  });

  final List<String> hints;
  final AquaColors? colors;
  final Function(String hint) onHintSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      ),
      child: Container(
        height: 49,
        constraints: const BoxConstraints(
          minWidth: 80,
        ),
        child: Material(
          color: colors?.surfacePrimary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (index, hint) in hints.indexed) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => onHintSelected(hint),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith((state) {
                      if (state.isHovered) {
                        return Colors.transparent;
                      }
                      return null;
                    }),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16.5),
                      child: AquaText.body2SemiBold(text: hint),
                    ),
                  ),
                ),
                if (index < hints.length - 1)
                  VerticalDivider(
                    width: 0,
                    color: colors?.surfaceBorderPrimary,
                  ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
