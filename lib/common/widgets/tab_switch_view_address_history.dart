import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TabSwitchViewAddressHistory extends HookWidget {
  const TabSwitchViewAddressHistory({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.initialIndex = 0,
    this.disabledIndices = const [],
    required this.labels,
    required this.onChange,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<String> labels;
  final Function(int) onChange;
  final int initialIndex;
  final List<int> disabledIndices;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(
      initialLength: labels.length,
      initialIndex: initialIndex,
    );
    final getTabRadius = useCallback((int index) {
      if (index == 0) {
        return BorderRadius.horizontal(
            left: const Radius.circular(12.0),
            right: Radius.circular(tabController.index == 0 ? 12.0 : 12.0));
      }
      if (index == labels.length - 1) {
        return BorderRadius.horizontal(
            right: const Radius.circular(12.0),
            left: Radius.circular(
                tabController.index == labels.length - 1 ? 12.0 : 12.0));
      }
      return null;
    }, [tabController.index]);

    tabController.addListener(() {
      if (disabledIndices.contains(tabController.index)) {
        tabController.index = tabController.previousIndex;
      }
    });

    return Container(
      height: 40.0,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border.all(
          width: 0,
          color: Theme.of(context).colors.addressHistoryTabBarSelected,
        ),
        color: backgroundColor ??
            Theme.of(context).colors.addressHistoryTabBarUnSelected,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 28.0),
      child: TabBar(
        controller: tabController,
        onTap: onChange,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(),
        labelColor: Theme.of(context).colors.addressHistoryTabBarTextSelected,
        unselectedLabelColor:
            Theme.of(context).colors.addressHistoryTabBarTextUnSelected,
        labelPadding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        indicatorWeight: 0,
        padding: EdgeInsets.zero,
        tabs: labels
            .mapIndexed((index, text) => Container(
                  height: tabController.index == index ? 40.0 : 39.0,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    borderRadius: getTabRadius(index),
                    color: tabController.index == index
                        ? Theme.of(context).colors.addressHistoryTabBarSelected
                        : Theme.of(context)
                            .colors
                            .addressHistoryTabBarUnSelected,
                  ),
                  child: Tab(text: text),
                ))
            .toList(),
      ),
    );
  }
}
