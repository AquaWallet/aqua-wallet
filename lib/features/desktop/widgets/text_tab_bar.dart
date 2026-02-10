import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class TextTabBar extends HookWidget {
  final List<HistoryOfAccountUiModel> tabs;
  final void Function(HistoryOfAccountUiModel tab) onTabChanged;
  final HistoryOfAccount selectedTab;
  final EdgeInsets margin;
  final double itemPadding;

  TextTabBar({
    required this.tabs,
    required this.onTabChanged,
    required this.selectedTab,
    this.margin = const EdgeInsets.symmetric(vertical: 16),
    this.itemPadding = 16,
    super.key,
  }) : assert(tabs.isNotEmpty, 'tabs list cannot be empty');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isTabLastItem = index == tabs.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              right: isTabLastItem ? 0 : itemPadding,
            ),
            child: GestureDetector(
              onTap: () => onTabChanged(tab),
              child: AquaText.body1SemiBold(
                text: tab.name,
                color: selectedTab == tab.type
                    ? context.aquaColors.textPrimary
                    : context.aquaColors.textTertiary,
              ),
            ),
          );
        }),
      ),
    );
  }
}
