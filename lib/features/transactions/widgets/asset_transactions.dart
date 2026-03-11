import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart' hide kAppBarHeight;
import 'package:aqua/features/shared/utils/transaction_item_localizations_extension.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final _logger = CustomLogger(FeatureFlag.transactions);

class AssetTransactions extends HookConsumerWidget {
  const AssetTransactions({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresherKey = useMemoized(UniqueKey.new);
    final itemUiModels = ref.watch(transactionsProvider(asset));
    final pendingPegTxns = useMemoized(
      () => [
        ...?itemUiModels.valueOrNull
            ?.whereType<PendingTransactionUiModel>()
            .map((model) => model.dbTransaction)
            .whereNotNull()
            .where((model) => model.isPeg && model.serviceOrderId != null)
      ],
      [itemUiModels],
    );
    final balanceAsset = ref
        .watch(assetsProvider)
        .asData
        ?.value
        .firstWhereOrNull((a) => a.id == asset.id);
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getAssetDisplayUnit(asset)));

    final conversion = useMemoized(
      () => balanceAsset != null
          ? ref
              .read(conversionProvider((balanceAsset, balanceAsset.amount)))
              ?.formattedWithCurrency
          : null,
      [balanceAsset],
    );

    // Periodically request order status for pending Peg transactions
    useEffect(() {
      void requestPegStatuses(List<TransactionDbModel> pendingPegTxns) {
        _logger.debug('Updating peg status for ${pendingPegTxns.length} items');
        for (final item in pendingPegTxns) {
          ref.read(pegStatusProvider.notifier).requestPegStatus(
                orderId: item.serviceOrderId!,
                isPegIn: item.isPegIn,
              );
        }
      }

      requestPegStatuses(pendingPegTxns);

      final timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => requestPegStatuses(pendingPegTxns),
      );

      return timer.cancel;
    }, [pendingPegTxns.length]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AquaPullToRefresh(
        key: refresherKey,
        colors: context.aquaColors,
        enablePullDown: true,
        onRefresh: () async {
          // fake delay to give impression of loading
          await Future.delayed(const Duration(seconds: 2));

          ref.invalidate(networkTransactionsProvider(asset));
          ref.invalidate(transactionsProvider(asset));
        },
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: itemUiModels.when(
          skipLoadingOnReload: true,
          loading: () => _HeaderWrappedContent(
            asset: asset,
            conversion: conversion,
            balanceAsset: balanceAsset,
            child: const CircularProgressIndicator(),
          ),
          error: (error, stack) => _HeaderWrappedContent(
            asset: asset,
            conversion: conversion,
            balanceAsset: balanceAsset,
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _HeaderWrappedContent(
                asset: asset,
                conversion: conversion,
                balanceAsset: balanceAsset,
                child: Text(
                  context.loc.assetTransactionsLiquidEmptyList(asset.name),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            } else {
              final pendingItems = [
                ...items.whereType<PendingTransactionUiModel>()
              ];
              final normalItems = [
                ...items.whereType<NormalTransactionUiModel>()
              ];
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //ANCHOR - Header
                    AquaAccountBalance(
                      asset: asset.toUiModel(
                        amountFiat: conversion,
                        displayUnit: displayUnit,
                      ),
                      amountWidget: AssetCryptoAmount(
                        asset: balanceAsset ?? asset,
                        style: AquaTypography.h5SemiBold,
                        showUnit: false,
                        usdtPrecisionOverride: asset.precision,
                      ),
                      colors: context.aquaColors,
                    ),
                    const SizedBox(height: 20),
                    //ANCHOR - Transactions Label
                    AquaText.body1SemiBold(
                      text: context.loc.transactions,
                    ),
                    const SizedBox(height: 12),
                    if (pendingItems.isNotEmpty) ...[
                      _TransactionsList(
                        items: pendingItems,
                        asset: asset,
                        isPending: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _TransactionsList(
                      items: normalItems,
                      asset: asset,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _HeaderWrappedContent extends ConsumerWidget {
  const _HeaderWrappedContent({
    required this.asset,
    required this.conversion,
    required this.balanceAsset,
    required this.child,
  });

  final Asset asset;
  final String? conversion;
  final Asset? balanceAsset;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getAssetDisplayUnit(asset)));

    return Column(
      children: [
        //ANCHOR - Header
        Container(
          margin: const EdgeInsets.only(top: 24, bottom: 20),
          child: AquaAccountBalance(
            asset: asset.toUiModel(
              amountFiat: conversion,
              displayUnit: displayUnit,
            ),
            amountWidget: AssetCryptoAmount(
              asset: balanceAsset ?? asset,
              style: AquaTypography.h5SemiBold,
              showUnit: false,
            ),
            colors: context.aquaColors,
          ),
        ),
        Expanded(
          child: Center(
            child: child,
          ),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.items,
    required this.asset,
    this.isPending = false,
  });

  final List<TransactionUiModel> items;
  final Asset asset;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ListView.separated(
        primary: false,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => AquaDivider(
          colors: context.aquaColors,
        ),
        itemBuilder: (_, index) => items[index].mapOrNull(
          normal: (item) => _AssetTransactionListItem(
            isPending: isPending,
            itemUiModel: item,
            // For peg transactions, use the asset where the network
            // transaction lives, not the "from" asset shown in the UI
            onTap: (item) => context.push(
              AssetTransactionDetailsScreen.routeName,
              extra: TransactionDetailsArgs(
                asset: item.dbTransaction?.isPeg == true ? asset : item.asset,
                transactionId: item.transaction.txhash ?? '',
              ),
            ),
          ),
          pending: (item) {
            final transactionId = item.transactionId?.isNotEmpty == true
                ? item.transactionId!
                : item.dbTransaction?.serviceOrderId ??
                    item.dbTransaction?.txhash;
            if (transactionId == null) {
              //TODO: Just an extra safe-guard, should be removed later
              //Transaction with missing ID should be filtered out at provider level
              return const SizedBox.shrink();
            }
            return _PendingTransactionListItem(
              itemUiModel: item,
              onTap: (item) => context.push(
                AssetTransactionDetailsScreen.routeName,
                extra: TransactionDetailsArgs(
                  // For peg transactions, use the asset where the network
                  // transaction lives, not the "from" asset shown in the UI
                  asset: item.dbTransaction?.isPeg == true ? asset : item.asset,
                  transactionId: transactionId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AssetTransactionListItem extends HookConsumerWidget {
  const _AssetTransactionListItem(
      {required this.itemUiModel, required this.onTap, this.isPending = false});

  final bool isPending;
  final NormalTransactionUiModel itemUiModel;
  final Function(NormalTransactionUiModel item) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE - The fiat amount calculation depends on rate stream which updates
    // several times per second. That made it impossible to integrate it with
    // the transaction provider and send the fiat equivalent value as part of
    // the TransactionsUiModel. So we use a separate provider for it.
    final fiatAmount =
        ref.watch(fiatAmountProvider(itemUiModel)).valueOrNull ?? '';
    final dbTxn = itemUiModel.dbTransaction;
    //NOTE - Can't rely on asset id directly because the lightning refund is received as a liquid tnx
    final iconAssetId =
        dbTxn?.isLightning ?? false ? Asset.lightning().id : null;
    final dcFundedAddress = (dbTxn?.isTopUp ?? false)
        ? context.loc.assetTransactionsTypeTopup(dbTxn?.serviceAddress ?? '')
        : null;
    final isLightning = dbTxn?.isLightning ?? false;
    final isAltUsdt = dbTxn?.isUSDtSwap ?? false;
    final isBoltzRefund = dbTxn?.isBoltzRefund ?? false;
    final shouldShowMiniIcon = isLightning || isAltUsdt;

    final txLocalizations = context.loc.transactionItemLocalizations;

    return switch (itemUiModel.transaction.type) {
      _ when itemUiModel.isFeeTransaction => AquaTransactionItem.fee(
          onTap: () => onTap(itemUiModel),
          iconAssetId: iconAssetId,
          isPending: isPending,
          timestamp: itemUiModel.createdAt,
          amountCrypto: itemUiModel.cryptoAmount,
          amountFiat: fiatAmount,
          feeLabel:
              context.loc.assetTxFeeLabel(itemUiModel.feeForAsset!.ticker),
          isFailed: itemUiModel.isFailed,
          colors: context.aquaColors,
          text: txLocalizations,
        ),
      _ when ((dbTxn?.isAnySwap ?? false) && !itemUiModel.involvesUsdt) =>
        AquaTransactionItem.swap(
          onTap: () => onTap(itemUiModel),
          timestamp: itemUiModel.createdAt,
          amountCrypto: itemUiModel.cryptoAmount,
          amountFiat: fiatAmount,
          isPending: isPending,
          isFailed: itemUiModel.isFailed,
          colors: context.aquaColors,
          text: txLocalizations,
          fromAssetTicker: itemUiModel.asset.ticker,
          toAssetTicker: itemUiModel.otherAsset?.ticker ?? '',
        ),
      GdkTransactionTypeEnum.incoming => AquaTransactionItem.receive(
          onTap: () => onTap(itemUiModel),
          iconAssetId: iconAssetId,
          timestamp: itemUiModel.createdAt,
          amountCrypto: itemUiModel.cryptoAmount,
          amountFiat: fiatAmount,
          isPending: isPending,
          isFailed: itemUiModel.isFailed,
          isRefund: isBoltzRefund,
          colors: context.aquaColors,
          text: txLocalizations,
        ),
      GdkTransactionTypeEnum.outgoing => AquaTransactionItem.send(
          onTap: () => onTap(itemUiModel),
          iconAssetId: shouldShowMiniIcon ? dbTxn?.assetId : null,
          isPending: isPending,
          isTopUp: dbTxn?.isTopUp ?? false,
          dcFundedAddress: dcFundedAddress,
          timestamp: itemUiModel.createdAt,
          amountCrypto: itemUiModel.cryptoAmount,
          amountFiat: fiatAmount,
          isFailed: itemUiModel.isFailed,
          colors: context.aquaColors,
          text: txLocalizations,
        ),
      GdkTransactionTypeEnum.swap => AquaTransactionItem.swap(
          onTap: () => onTap(itemUiModel),
          timestamp: itemUiModel.createdAt,
          amountCrypto: itemUiModel.cryptoAmount,
          amountFiat: '',
          isPending: isPending,
          isFailed: itemUiModel.isFailed,
          colors: context.aquaColors,
          text: txLocalizations,
          fromAssetTicker: itemUiModel.isOutgoingAsset
              ? itemUiModel.asset.ticker
              : itemUiModel.otherAsset?.ticker ?? '',
          toAssetTicker: itemUiModel.isOutgoingAsset
              ? itemUiModel.otherAsset?.ticker ?? ''
              : itemUiModel.asset.ticker,
        ),
      GdkTransactionTypeEnum.redeposit => AquaTransactionItem.redeposit(
          onTap: () => onTap(itemUiModel),
          iconAssetId: iconAssetId,
          timestamp: itemUiModel.createdAt,
          amountCrypto: itemUiModel.cryptoAmount,
          amountFiat: fiatAmount,
          colors: context.aquaColors,
          text: txLocalizations,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _PendingTransactionListItem extends HookConsumerWidget {
  const _PendingTransactionListItem({
    required this.itemUiModel,
    required this.onTap,
  });

  final PendingTransactionUiModel itemUiModel;
  final Function(PendingTransactionUiModel item) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE - The fiat amount calculation depends on rate stream which updates
    // several times per second. That made it impossible to integrate it with
    // the transaction provider and send the fiat equivalent value as part of
    // the TransactionsUiModel. So we use a separate provider for it.
    final fiatAmount =
        ref.watch(fiatAmountProvider(itemUiModel)).valueOrNull ?? '';
    final dbTxn = itemUiModel.dbTransaction;
    final assetId = dbTxn?.isLightning ?? false ? dbTxn?.assetId : null;

    final txLocalizations = context.loc.transactionItemLocalizations;
    if (itemUiModel.isFeeTransaction) {
      return AquaTransactionItem.fee(
        onTap: () => onTap(itemUiModel),
        iconAssetId: assetId,
        timestamp: itemUiModel.createdAt,
        amountCrypto: '',
        amountFiat: '',
        feeLabel: context.loc.assetTxFeeLabel(itemUiModel.feeForAsset!.ticker),
        isPending: true,
        colors: context.aquaColors,
        text: txLocalizations,
      );
    }

    // If dbTxn is null this txn is a pending incoming transaction
    return dbTxn == null
        ? AquaTransactionItem.receive(
            onTap: () => onTap(itemUiModel),
            iconAssetId: assetId,
            timestamp: itemUiModel.createdAt,
            amountCrypto: itemUiModel.cryptoAmount,
            amountFiat: fiatAmount,
            isPending: true,
            colors: context.aquaColors,
            text: txLocalizations,
          )
        : switch (dbTxn.type) {
            _ when dbTxn.isPeg => AquaTransactionItem.swap(
                onTap: () => onTap(itemUiModel),
                timestamp: itemUiModel.createdAt,
                amountCrypto: '',
                amountFiat: '',
                isPending: true,
                colors: context.aquaColors,
                text: txLocalizations,
                fromAssetTicker: itemUiModel.asset.ticker,
                toAssetTicker: itemUiModel.otherAsset?.ticker ?? '',
              ),
            _ when (dbTxn.isAnySwap && !dbTxn.isUSDtSwap) =>
              AquaTransactionItem.swap(
                onTap: () => onTap(itemUiModel),
                timestamp: itemUiModel.createdAt,
                amountCrypto: itemUiModel.cryptoAmount,
                amountFiat: fiatAmount,
                isPending: true,
                colors: context.aquaColors,
                text: txLocalizations,
                fromAssetTicker: itemUiModel.asset.ticker,
                toAssetTicker: itemUiModel.otherAsset?.ticker ?? '',
              ),
            _ when (dbTxn.isBoltzReverseSwap || dbTxn.isBoltzRefund) =>
              AquaTransactionItem.receive(
                onTap: () => onTap(itemUiModel),
                iconAssetId: assetId,
                timestamp: itemUiModel.createdAt,
                amountCrypto: itemUiModel.cryptoAmount,
                amountFiat: fiatAmount,
                isPending: true,
                isRefund: dbTxn.isBoltzRefund,
                colors: context.aquaColors,
                text: txLocalizations,
              ),
            _ => AquaTransactionItem.send(
                onTap: () => onTap(itemUiModel),
                iconAssetId: assetId,
                timestamp: itemUiModel.createdAt,
                amountCrypto: itemUiModel.cryptoAmount,
                amountFiat: fiatAmount,
                isTopUp: dbTxn.isTopUp,
                isPending: true,
                colors: context.aquaColors,
                text: txLocalizations,
              ),
          };
  }
}
