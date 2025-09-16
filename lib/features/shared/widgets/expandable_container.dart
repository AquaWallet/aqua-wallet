import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/widgets/tight_expand_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ExpandableContainer extends HookConsumerWidget {
  const ExpandableContainer({
    super.key,
    required this.title,
    required this.child,
    this.padding,
    this.color,
  });

  final Widget title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState<bool>(false);

    return Container(
      color: color,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: title,
            isExpanded: isExpanded,
          ),
          if (isExpanded.value) ...[
            child,
          ]
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isExpanded,
  });

  final Widget title;
  final ValueNotifier<bool> isExpanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => isExpanded.value = !isExpanded.value,
      child: Row(
        children: [
          Expanded(child: title),
          TightExpandIcon(
            size: 20.0,
            onPressed: null,
            padding: EdgeInsets.zero,
            disabledColor: Theme.of(context).colors.onBackground,
            expandedColor: Theme.of(context).colors.onBackground,
            isExpanded: isExpanded.value,
          ),
        ],
      ),
    );
  }
}
