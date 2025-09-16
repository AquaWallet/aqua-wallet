import 'package:coin_cz/config/colors/aqua_colors.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CreateCardPlaceholder extends StatelessWidget {
  const CreateCardPlaceholder({
    super.key,
    required this.onCreateCard,
  });

  final VoidCallback onCreateCard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCreateCard,
      child: DottedBorder(
        color: AquaColors.blueGreen,
        strokeWidth: 2,
        dashPattern: const [4.0, 2.0],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AquaColors.blueGreen.withOpacity(0.15),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 48,
                    color: AquaColors.blueGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.loc.debitCardCreateCard,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AquaColors.blueGreen,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
