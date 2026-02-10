import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class BoltzSwapsScreen extends HookConsumerWidget {
  static const routeName = '/boltzSwapsScreen';

  const BoltzSwapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = useMemoized(() => [context.loc.send, context.loc.receive], []);
    final selectedTab = useState(0);
    final searchController = useTextEditingController();

    final type = selectedTab.value == 0 ? SwapType.submarine : SwapType.reverse;
    final state = ref.watch(boltzSwapsFilterProvider(type)).valueOrNull;

    final swaps = useMemoized(
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
                  .read(boltzSwapsFilterProvider(type).notifier)
                  .updateSearchQuery(value),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BoltzSwapsList(
                swaps: swaps,
                hasMore: hasMore,
                onLoadMore: () => ref
                    .read(boltzSwapsFilterProvider(type).notifier)
                    .fetchNext(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
