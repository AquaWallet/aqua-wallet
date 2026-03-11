import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SwapOrdersScreen extends HookConsumerWidget {
  static const routeName = '/swapOrdersScreen';

  const SwapOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = useMemoized(
      () => [context.loc.active, context.loc.history],
      [],
    );
    final selectedTab = useState(0);
    final searchController = useTextEditingController();

    final filterType = selectedTab.value == 0
        ? SwapOrderFilterType.active
        : SwapOrderFilterType.history;

    // Clear search when switching tabs
    useEffect(() {
      searchController.clear();
      ref.read(swapOrdersFilterProvider(filterType).notifier).clearSearch();
      return null;
    }, [filterType]);

    final state = ref.watch(swapOrdersFilterProvider(filterType)).valueOrNull;

    final orders = useMemoized(
      () => state?.items ?? [],
      [state],
    );
    final hasMore = useMemoized(
      () => state?.hasMore ?? false,
      [state],
    );

    return DesignRevampScaffold(
      extendBodyBehindAppBar: false,
      appBar: AquaTopAppBar(
        title: context.loc.swapOrders,
        showBackButton: true,
        colors: context.aquaColors,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AquaTabBar(
              height: 36,
              tabs: tabs,
              onTabChanged: (index) => selectedTab.value = index,
            ),
            const SizedBox(height: 24),
            AquaSearchField(
              hint: context.loc.searchTitle,
              controller: searchController,
              onChanged: (value) => ref
                  .read(swapOrdersFilterProvider(filterType).notifier)
                  .updateSearchQuery(value),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SwapOrdersList(
                orders: orders,
                hasMore: hasMore,
                onLoadMore: () => ref
                    .read(swapOrdersFilterProvider(filterType).notifier)
                    .fetchNext(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
