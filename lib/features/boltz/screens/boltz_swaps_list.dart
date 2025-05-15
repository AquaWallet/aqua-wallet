import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/boltz/screens/boltz_swap_detail_screen.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:boltz_dart/boltz_dart.dart';

class BoltzSwapsList extends HookConsumerWidget {
  const BoltzSwapsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapsState = ref.watch(boltzStorageProvider);

    return ListView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 20.0),
          child: Text(context.loc.boltzSwapsListSendHeading,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        swapsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Error: $err'),
          data: (swaps) {
            final submarineSwaps =
                swaps.where((swap) => swap.kind == SwapType.submarine).toList();
            return submarineSwaps.isNotEmpty
                ? ListView.separated(
                    primary: false,
                    shrinkWrap: true,
                    itemCount: submarineSwaps.length,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        left: 28.0, right: 28.0, top: 20.0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16.0),
                    itemBuilder: (_, index) =>
                        _NormalSwapListItem(submarineSwaps[index]),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 20.0),
                    child: Text(
                      context.loc.boltzSwapsListEmptyState,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 20.0),
          child: Text(context.loc.boltzSwapsListReceiveHeading,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        swapsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Error: $err'),
          data: (swaps) {
            final reverseSwaps =
                swaps.where((swap) => swap.kind == SwapType.reverse).toList();
            return reverseSwaps.isNotEmpty
                ? ListView.separated(
                    primary: false,
                    shrinkWrap: true,
                    itemCount: reverseSwaps.length,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        left: 28.0, right: 28.0, top: 20.0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16.0),
                    itemBuilder: (_, index) =>
                        _ReverseSwapListItem(reverseSwaps[index]),
                  )
                : Padding(
                    padding: const EdgeInsets.only(
                        left: 32.0, right: 32.0, top: 10.0, bottom: 10.0),
                    child: Text(
                      context.loc.boltzSwapsListEmptyState,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
          },
        ),
      ],
    );
  }
}

class BaseSwapListItem extends HookConsumerWidget {
  final BoltzSwapDbModel swapData;
  final VoidCallback onTap;

  const BaseSwapListItem({
    super.key,
    required this.swapData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.0),
      bordered: !darkMode,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  //ANCHOR - Status
                  Text(
                    "${context.loc.status}: ${swapData.lastKnownStatus?.value ?? 'Unknown'}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  //TODO: asset amount widget
                  //ANCHOR - Amount
                  Expanded(
                    child: Text(
                      '${swapData.amountFromInvoice}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ]),
                const SizedBox(height: 10.0),
                Text('${context.loc.boltzId}: ${swapData.boltzId}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 13.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                const SizedBox(height: 8.0),
                Text(
                    '${context.loc.boltzTimeoutBlockHeight}: ${swapData.locktime}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 13.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NormalSwapListItem extends StatelessWidget {
  final BoltzSwapDbModel swapData;

  const _NormalSwapListItem(this.swapData);

  @override
  Widget build(BuildContext context) {
    return BaseSwapListItem(
      swapData: swapData,
      onTap: () {
        context.push(
          BoltzSwapDetailScreen.routeName,
          extra: swapData,
        );
      },
    );
  }
}

class _ReverseSwapListItem extends StatelessWidget {
  final BoltzSwapDbModel swapData;

  const _ReverseSwapListItem(this.swapData);

  @override
  Widget build(BuildContext context) {
    return BaseSwapListItem(
      swapData: swapData,
      onTap: () {
        context.push(
          BoltzSwapDetailScreen.routeName,
          extra: swapData,
        );
      },
    );
  }
}
