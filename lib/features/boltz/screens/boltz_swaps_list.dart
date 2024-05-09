import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/boltz/screens/boltz_swap_detail_screen.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

class BoltzSwapsList extends HookConsumerWidget {
  const BoltzSwapsList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalSwaps = ref.watch(boltzAllSwapsProvider);
    final reverseSwaps = ref.watch(boltzAllReverseSwapsProvider);

    return ListView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 20.h),
          child: Text(context.loc.boltzSwapsListSendHeading,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        normalSwaps.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error: $err'),
          data: (normalSwaps) => normalSwaps.isNotEmpty
              ? ListView.separated(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: normalSwaps.length,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(left: 28.w, right: 28.w, top: 20.h),
                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
                  itemBuilder: (_, index) =>
                      _NormalSwapListItem(normalSwaps[index]),
                )
              : Padding(
                  padding: EdgeInsets.only(
                      left: 32.w, right: 32.w, top: 20.h, bottom: 20.h),
                  child: Text(
                    context.loc.boltzSwapsListEmptyState,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 20.h),
          child: Text(context.loc.boltzSwapsListReceiveHeading,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        reverseSwaps.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error: $err'),
          data: (reverseSwaps) => reverseSwaps.isNotEmpty
              ? ListView.separated(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: reverseSwaps.length,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(left: 28.w, right: 28.w, top: 20.h),
                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
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
                ),
        ),
      ],
    );
  }
}

class BaseSwapListItem extends HookConsumerWidget {
  final dynamic swapData;
  final String swapStatus;
  final String id;
  final String address;
  final int timeoutBlockHeight;
  final String amount;

  const BaseSwapListItem({
    Key? key,
    required this.swapData,
    required this.swapStatus,
    required this.id,
    required this.address,
    required this.timeoutBlockHeight,
    required this.amount,
  }) : super(key: key);

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
          onTap: () {
            Navigator.of(context).pushNamed(
              BoltzSwapDetailScreen.routeName,
              arguments: swapData,
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  //ANCHOR - Status
                  Text(
                    "${context.loc.status}: $swapStatus",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  //ANCHOR - Amount
                  Expanded(
                    child: Text(
                      amount,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ]),
                SizedBox(height: 10.h),
                Text('${context.loc.boltzId}: $id',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 13.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                SizedBox(height: 8.h),
                Text('${context.loc.address}: $address',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 13.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                SizedBox(height: 8.h),
                Text(
                    '${context.loc.boltzTimeoutBlockHeight}: $timeoutBlockHeight',
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
  final BoltzSwapData swapData;

  const _NormalSwapListItem(this.swapData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseSwapListItem(
      swapData: swapData,
      swapStatus: swapData.swapStatus.value,
      id: swapData.response.id,
      address: swapData.response.address,
      timeoutBlockHeight: swapData.response.timeoutBlockHeight,
      amount:
          '${BoltzService.getAmountFromLightningInvoice(swapData.request.invoice)}',
    );
  }
}

class _ReverseSwapListItem extends StatelessWidget {
  final BoltzReverseSwapData swapData;

  const _ReverseSwapListItem(this.swapData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseSwapListItem(
      swapData: swapData,
      swapStatus: swapData.swapStatus.value,
      id: swapData.response.id,
      address: swapData.request.address ?? 'N/A',
      timeoutBlockHeight: swapData.response.timeoutBlockHeight,
      amount: '${swapData.request.invoiceAmount}',
    );
  }
}
