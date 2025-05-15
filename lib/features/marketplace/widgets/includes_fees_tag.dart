import 'package:aqua/config/config.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';

class IncludesFeesTag extends StatelessWidget {
  const IncludesFeesTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colors.inverseSurfaceColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        context.loc.inclFees,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
