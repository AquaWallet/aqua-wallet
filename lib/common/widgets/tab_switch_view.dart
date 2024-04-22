import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TabSwitchView extends HookWidget {
  const TabSwitchView({
    Key? key,
    this.backgroundColor,
    this.foregroundColor,
    this.initialIndex = 0,
    this.disabledIndices = const [],
    required this.labels,
    required this.onChange,
  }) : super(key: key);

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
        return BorderRadius.horizontal(left: Radius.circular(10.r));
      }
      if (index == labels.length - 1) {
        return BorderRadius.horizontal(right: Radius.circular(10.r));
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
      padding: labels.length > 2 ? EdgeInsets.all(2.h) : EdgeInsets.zero,
      decoration: BoxDecoration(
        boxShadow: [Theme.of(context).shadow],
        color:
            backgroundColor ?? Theme.of(context).colors.tabSelectedBackground,
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      child: TabBar(
        controller: tabController,
        onTap: onChange,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(),
        labelColor: Theme.of(context).colors.tabSelectedForeground,
        unselectedLabelColor: Theme.of(context).colors.tabUnselectedForeground,
        labelPadding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        indicatorWeight: 0,
        padding: EdgeInsets.zero,
        tabs: labels
            .mapIndexed((index, text) => Container(
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    borderRadius: getTabRadius(index),
                    border: labels.length > 2 &&
                            index != 0 &&
                            index != labels.length - 1
                        ? Border.symmetric(
                            vertical: BorderSide(
                              color: Theme.of(context)
                                  .colors
                                  .tabSelectedBackground,
                              width: 1.25.w,
                            ),
                          )
                        : null,
                    color: tabController.index == index
                        ? Theme.of(context).colors.tabSelectedBackground
                        : Theme.of(context).colors.tabUnselectedBackground,
                  ),
                  child: Tab(text: text),
                ))
            .toList(),
      ),
    );
  }
}
