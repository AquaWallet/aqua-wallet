import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
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
          padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 20.h),
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
                    padding:
                        EdgeInsets.only(left: 28.w, right: 28.w, top: 20.h),
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (_, index) =>
                        _NormalSwapListItem(submarineSwaps[index]),
                  )
                : Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
                    child: Text(
                      context.loc.boltzSwapsListEmptyState,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 20.h),
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
                    padding:
                        EdgeInsets.only(left: 28.w, right: 28.w, top: 20.h),
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (_, index) =>
                        _ReverseSwapListItem(reverseSwaps[index]),
                  )
                : Padding(
                    padding: EdgeInsets.only(
                        left: 32.w, right: 32.w, top: 10.h, bottom: 10.h),
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
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      bordered: !darkMode,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  //ANCHOR - Status
                  Text(
                    "${context.loc.status}: ${swapData.lastKnownStatus?.value ?? 'Unknown'}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  //ANCHOR - Amount
                  Expanded(
                    child: Text(
                      '${swapData.amountFromInvoice}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ]),
                SizedBox(height: 10.h),
                Text('${context.loc.boltzId}: ${swapData.boltzId}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 13.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                SizedBox(height: 8.h),
                Text(
                    '${context.loc.boltzTimeoutBlockHeight}: ${swapData.locktime}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 13.sp,
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
        Navigator.of(context).pushNamed(
          BoltzSwapDetailScreen.routeName,
          arguments: swapData,
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
        Navigator.of(context).pushNamed(
          BoltzSwapDetailScreen.routeName,
          arguments: swapData,
        );
      },
    );
  }
}
