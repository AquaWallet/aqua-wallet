import 'dart:math';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetTransactions extends HookConsumerWidget {
  const AssetTransactions({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            padding: const EdgeInsets.only(top: 30.0),
            child: SmartRefresher(
              key: refresherKey,
              enablePullDown: true,
              controller: controller,
              physics: const BouncingScrollPhysics(),
              onRefresh: () async {
                // fake delay to give impression of loading
                await Future.delayed(const Duration(seconds: 1));

                ref.invalidate(networkTransactionsProvider(asset));
                ref.invalidate(transactionsProvider(asset));

                // hide loading animation
                controller.refreshCompleted();
              },
              header: ClassicHeader(
                height: 60.0,
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
                padding: const EdgeInsets.only(
                  left: 28.0,
                  right: 28.0,
                  top: 20.0,
                  bottom: 50.0,
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16.0),
                itemBuilder: (_, index) {
                  final item = listItems[index];
                  return switch (item) {
                    _ when (item is NormalTransactionUiModel) =>
                      _AssetTransactionListItem(item),
                    _ when (item is GhostTransactionUiModel) =>
                      _GhostAssetTransactionListItem(item),
                    _ => const TransactionsTitle(),
                  };
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
        top: context.adaptiveDouble(mobile: 25.0, smallMobile: 15.0),
      ),
      decoration: BoxDecoration(
        gradient: Theme.of(context).getFadeGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          color: Theme.of(context).colors.background,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: context.adaptiveDouble(
                  mobile: 25.0,
                  smallMobile: 5.0)), // Adds 25 space above the text
          Text(
            context.loc.assetTransactionsListTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _AssetTransactionListItem extends HookConsumerWidget {
  const _AssetTransactionListItem(this.itemUiModel);

  final TransactionUiModel itemUiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    final cryptoAmountInSats = useMemoized(() {
      final cryptoAmount =
          Decimal.tryParse(itemUiModel.cryptoAmount.replaceAll(',', ''));
      return itemUiModel.asset.isAnyUsdt
          ? ((cryptoAmount ?? Decimal.zero) *
                  Decimal.fromInt(pow(10, itemUiModel.asset.precision).toInt()))
              .toInt()
          : ref.read(formatterProvider).parseAssetAmountDirect(
                amount: itemUiModel.cryptoAmount,
                precision: itemUiModel.asset.precision,
              );
    }, [itemUiModel]);

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.0),
      bordered: !darkMode,
      borderWidth: 1.0,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: () => context.push(
            AssetTransactionDetailsScreen.routeName,
            extra: itemUiModel,
          ),
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            height: 80.0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                //ANCHOR - Icon
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colors.listItemRoundedIconBackground,
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: SvgPicture.asset(
                    itemUiModel.icon,
                    width: 10.0,
                    height: 10.0,
                    fit: BoxFit.scaleDown,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
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
                              child: AssetCryptoAmount(
                                  showUnit: false,
                                  asset: itemUiModel.asset,
                                  amount: cryptoAmountInSats.toString(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                        ]),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(children: [
                            //ANCHOR - Transaction Type
                            Text(
                              itemUiModel.type(context),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontSize: 13.0,
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

class _GhostAssetTransactionListItem extends HookConsumerWidget {
  const _GhostAssetTransactionListItem(this.itemUiModel);

  final GhostTransactionUiModel itemUiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DottedBorder(
      strokeWidth: 1.0,
      color: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      radius: const Radius.circular(12.0),
      borderType: BorderType.RRect,
      dashPattern: const [4.0, 6.0],
      child: _AssetTransactionListItem(itemUiModel),
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
    return AssetCryptoAmount(
      amount: amount,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 13.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}
