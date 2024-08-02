import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
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
            left: Radius.circular(12.r),
            right: Radius.circular(tabController.index == 0 ? 12.r : 12.r));
      }
      if (index == labels.length - 1) {
        return BorderRadius.horizontal(
            right: Radius.circular(12.r),
            left: Radius.circular(
                tabController.index == labels.length - 1 ? 12.r : 12.r));
      }
      return null;
    }, [tabController.index]);

    tabController.addListener(() {
      if (disabledIndices.contains(tabController.index)) {
        tabController.index = tabController.previousIndex;
      }
    });

    return Container(
      height: 40.h,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border.all(
          width: 0,
          color: Theme.of(context).colors.addressHistoryTabBarSelected,
        ),
        color: backgroundColor ??
            Theme.of(context).colors.addressHistoryTabBarUnSelected,
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 28.w),
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
                  height: tabController.index == index ? 40.h : 39.h,
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
