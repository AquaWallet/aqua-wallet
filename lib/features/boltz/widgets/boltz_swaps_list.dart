import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class BoltzSwapsList extends HookConsumerWidget {
  const BoltzSwapsList({
    super.key,
    required this.swaps,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<BoltzSwapDbModel> swaps;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.8) {
          if (hasMore) {
            onLoadMore();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [hasMore]);

    if (swaps.isEmpty) {
      return const BoltzSwapsListEmptyView();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: ListView.separated(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: swaps.length + (hasMore ? 1 : 0),
        padding: EdgeInsets.zero,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (_, index) {
          if (hasMore && index == swaps.length) {
            // Not really needed because DB fetch takes milliseconds to complete
            return const Center(child: CircularProgressIndicator());
          }
          return _SwapListItem(swap: swaps[index]);
        },
      ),
    );
  }
}

class _SwapListItem extends ConsumerWidget {
  const _SwapListItem({required this.swap});

  final BoltzSwapDbModel swap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedAmount = swap.amountFromInvoice != null
        ? ref.watch(currencyFormatProvider(0)).format(swap.amountFromInvoice!)
        : null;
    final amountWithUnit = formattedAmount != null
        ? '$formattedAmount ${SupportedDisplayUnits.sats.value}'
        : null;

    return AquaListItem(
      title: swap.boltzId,
      subtitle: context.loc.timeout(swap.locktime),
      titleTrailing: amountWithUnit,
      subtitleTrailing: swap.lastKnownStatus?.label(context) ?? '',
      iconTrailing: AquaIcon.chevronRight(
        size: 18,
        color: context.aquaColors.textSecondary,
      ),
      colors: context.aquaColors,
      onTap: () => context.push(
        BoltzSwapDetailScreen.routeName,
        extra: swap,
      ),
    );
  }
}
