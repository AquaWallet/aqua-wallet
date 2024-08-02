import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetTransactions extends HookConsumerWidget {
  const AssetTransactions({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ModalRoute.of(context)?.settings.arguments as Asset;
    final itemUiModels = ref.watch(transactionsProvider(asset));
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));

    return itemUiModels.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              asset.isBTC
                  ? context.loc.assetTransactionsItemBitcoinEmpty
                  : context.loc.assetTransactionsLiquidEmptyList(asset.name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        } else {
          final listItems = [null, ...items];
          return Container(
            padding: EdgeInsets.only(top: 30.h),
            child: SmartRefresher(
              key: refresherKey,
              enablePullDown: true,
              controller: controller,
              physics: const BouncingScrollPhysics(),
              onRefresh: () async {
                // fake delay to give impression of loading
                await Future.delayed(const Duration(seconds: 1));

                ref.invalidate(rawTransactionsProvider(asset));
                ref.invalidate(transactionsProvider(asset));

                // hide loading animation
                controller.refreshCompleted();
              },
              header: ClassicHeader(
                height: 60.h,
                refreshingText: '',
                releaseText: '',
                completeText: '',
                failedText: '',
                idleText: '',
                idleIcon: null,
                failedIcon: null,
                releaseIcon: null,
                refreshingIcon: null,
                completeIcon: null,
                outerBuilder: (child) => Container(child: child),
              ),
              child: ListView.separated(
                primary: false,
                shrinkWrap: true,
                itemCount: listItems.length,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  left: 28.w,
                  right: 28.w,
                  top: 20.h,
                  bottom: 50.h,
                ),
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (_, index) {
                  final item = listItems[index];
                  return item == null
                      ? const TransactionsTitle()
                      : _AssetTransactionListItem(item);
                },
              ),
            ),
          );
        }
      },
    );
  }
}

class TransactionsTitle extends StatelessWidget {
  const TransactionsTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 25.h,
      ),
      decoration: BoxDecoration(
        gradient: Theme.of(context).getFadeGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          color: Theme.of(context).colorScheme.background,
        ),
      ),
      child: Text(
        context.loc.assetTransactionsListTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _AssetTransactionListItem extends HookConsumerWidget {
  const _AssetTransactionListItem(this.itemUiModel);

  final TransactionUiModel itemUiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      bordered: !darkMode,
      borderWidth: 1.w,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              AssetTransactionDetailsScreen.routeName,
              arguments: itemUiModel,
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 80.h,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Row(
              children: [
                //ANCHOR - Icon
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colors.listItemRoundedIconBackground,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: SvgPicture.asset(
                    itemUiModel.icon,
                    width: 10.w,
                    height: 10.h,
                    fit: BoxFit.scaleDown,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(children: [
                          //ANCHOR - Date
                          Text(
                            itemUiModel.createdAt,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          //ANCHOR - Amount
                          Expanded(
                            child: Text(
                              itemUiModel.cryptoAmount,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ]),
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Row(children: [
                            //ANCHOR - Transaction Type
                            Text(
                              itemUiModel.type(context),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontSize: 13.sp,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            //ANCHOR - USD Equivalent
                            Expanded(
                              child: FiatAmountLabel(model: itemUiModel),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FiatAmountLabel extends HookConsumerWidget {
  const FiatAmountLabel({
    super.key,
    required this.model,
  });

  final TransactionUiModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE - The fiat amount calculation depends on rate stream which updates
    // several times per second. That made it impossible to integrate it with
    // the transaction provider and send the fiat equivalent value as part of
    // the TransactionsUiModel. So we use a separate provider for it.
    final amount = ref.watch(fiatAmountProvider(model)).asData?.value ?? '';
    return Text(
      amount,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}
