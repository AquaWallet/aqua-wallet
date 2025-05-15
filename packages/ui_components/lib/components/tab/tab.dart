import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaTabBar extends HookWidget {
  final List<String> tabs;
  final ValueChanged<int>? onTabChanged;
  final int initialIndex;
  final Color? selectedColor;
  final Color? unselectedColor;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final EdgeInsets? padding;
  final double height;
  final double spacing;
  final BorderRadius? borderRadius;

  AquaTabBar({
    super.key,
    required this.tabs,
    this.onTabChanged,
    this.initialIndex = 0,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.padding,
    this.height = 40,
    this.spacing = 8,
    this.borderRadius,
  }) : assert(tabs.isNotEmpty, 'tabs list cannot be empty');

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        this.selectedColor ?? Theme.of(context).colorScheme.surface;
    final unselectedColor =
        this.unselectedColor ?? Theme.of(context).disabledColor;
    final borderRadius = this.borderRadius ?? BorderRadius.circular(8);

    final tabController = useTabController(
      initialLength: tabs.length,
      initialIndex: initialIndex,
    );

    useEffect(() {
      void handleTabSelection() {
        if (tabController.indexIsChanging) {
          onTabChanged?.call(tabController.index);
        }
      }

      tabController.addListener(handleTabSelection);
      return () => tabController.removeListener(handleTabSelection);
    }, [tabController]);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      padding: padding ?? const EdgeInsets.all(2),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        splashFactory: NoSplash.splashFactory,
        physics: const BouncingScrollPhysics(),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: Theme.of(context).colorScheme.onSurface,
        unselectedLabelColor: unselectedColor,
        labelStyle: selectedTextStyle ?? AquaTypography.body2SemiBold,
        unselectedLabelStyle:
            unselectedTextStyle ?? AquaTypography.body2SemiBold,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          color: selectedColor,
          borderRadius: borderRadius,
        ),
        tabs: tabs.map((tab) {
          return Tab(
            height: height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(tab),
            ),
          );
        }).toList(),
      ),
    );
  }
}
