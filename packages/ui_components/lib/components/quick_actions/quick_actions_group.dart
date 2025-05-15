import 'package:flutter/material.dart';

class AquaQuickActionsGroup extends StatelessWidget {
  const AquaQuickActionsGroup({
    super.key,
    required this.items,
  });

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Theme.of(context).colorScheme.error,
      color: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(maxHeight: 50),
      child: Row(
        children: [
          for (final item in items) ...[
            Expanded(
              child: item,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ],
      ),
    );
  }
}
