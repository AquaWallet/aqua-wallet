import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/shared/shared.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TabSwitchView extends HookConsumerWidget {
  const TabSwitchView({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    final tabController = useTabController(
      initialLength: labels.length,
      initialIndex: initialIndex,
    );
    final getTabRadius = useCallback((int index) {
      if (index == 0) {
        return const BorderRadius.horizontal(left: Radius.circular(10.0));
      }
      if (index == labels.length - 1) {
        return const BorderRadius.horizontal(right: Radius.circular(10.0));
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
      padding: labels.length > 2 ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
      decoration: BoxDecoration(
        boxShadow: [Theme.of(context).shadow],
        color: null,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 28.0),
      child: TabBar(
        controller: tabController,
        onTap: onChange,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(),
        labelColor: Theme.of(context).colors.tabSelectedForeground,
        unselectedLabelColor: darkMode
            ? Theme.of(context).colors.tabUnselectedForeground
            : Theme.of(context).colorScheme.surface,
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
                              width: 1.25,
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
