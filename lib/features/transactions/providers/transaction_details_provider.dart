// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:intl/intl.dart';
import 'package:aqua/constants.dart';

typedef Transaction = (Asset, GdkTransaction, BuildContext);

final assetTransactionDetailsProvider = AsyncNotifierProvider.family
    .autoDispose<
        AssetTransactionDetailsNotifier,
        AssetTransactionDetailsUiModel,
        Transaction?>(AssetTransactionDetailsNotifier.new);

class AssetTransactionDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<
    AssetTransactionDetailsUiModel, Transaction?> {
  @override
  FutureOr<AssetTransactionDetailsUiModel> build(Transaction? arg) async {
    if (arg == null) {
      throw AssetTransactionDetailsInvalidArgumentsException();
    }

    final asset = arg.$1;
    final transaction = arg.$2;
    final allAssets = ref.read(assetsProvider).asData?.value ?? [];
    final feeAsset =
        allAssets.firstWhere((a) => asset.isBTC ? a.isBTC : a.isLBTC);
    final network =
        asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

    final transactions = await network.getTransactions() ?? [];
    final updatedTransaction = transactions.firstWhereOrNull((txn) {
      return txn.txhash == transaction.txhash;
    });

    if (updatedTransaction == null) {
      throw AssetTransactionDetailsTransactionNotFoundException();
    }

    final assetList = updatedTransaction.satoshi?.keys
        .map((id) => ref.read(assetsProvider.notifier).liquidAssetById(id))
        .whereNotNull()
        .toList();
    final count = await ref
        .read(aquaProvider)
        .getConfirmationCount(
          asset: asset,
          transactionBlockHeight: updatedTransaction.blockHeight ?? 0,
        )
        .first;

    final arguments = TransactionDataArgument(
      transaction: updatedTransaction,
      transactionAsset: asset,
      feeAsset: feeAsset,
      satoshiAssets: assetList ?? [],
      confirmationCount: count,
    );

    final items = switch (transaction.type) {
      GdkTransactionTypeEnum.swap => await _swapItemUiModels(arg.$3, arguments),
      GdkTransactionTypeEnum.redeposit =>
        await _redepositItems(arg.$3, arguments),
      GdkTransactionTypeEnum.outgoing =>
        await _outgoingItems(arg.$3, arguments),
      GdkTransactionTypeEnum.incoming =>
        await _incomingItems(arg.$3, arguments),
      _ => <AssetTransactionDetailsItemUiModel>[],
    };

    return AssetTransactionDetailsUiModel(items: items);
  }

  Future<List<AssetTransactionDetailsItemUiModel>> _swapItemUiModels(
    BuildContext context,
    TransactionDataArgument arguments,
  ) async {
    final asset = arguments.transactionAsset;
    final transaction = arguments.transaction;
    final satoshiAssets = arguments.satoshiAssets;

    final items = <AssetTransactionDetailsItemUiModel>[];

    final type = AppLocalizations.of(context)!.assetTransactionsTypeSwap;
    final showPendingIndicator = asset.isBTC
        ? arguments.confirmationCount < onchainConfirmationBlockCount
        : arguments.confirmationCount < liquidConfirmationBlockCount;
    final date = await formattedDate(context, transaction.createdAtTs);
    items.add(AssetTransactionDetailsHeaderItemUiModel(
      type: type,
      showPendingIndicator: showPendingIndicator,
      date: date,
    ));

    final delivered = (transaction.swapOutgoingSatoshi as int).abs();
    final deliveredAsset = satoshiAssets!
        .firstWhere((asset) => asset.id == transaction.swapOutgoingAssetId);
    final formattedDelivered = ref.read(formatterProvider).formatAssetAmount(
          amount: delivered,
          precision: deliveredAsset.precision,
        );

    final deliveredText = '$formattedDelivered ${deliveredAsset.ticker}';
    items.add(AssetTransactionDetailsDataItemUiModel(
      title: AppLocalizations.of(context)!.assetTransactionDetailsDelivered,
      value: deliveredText,
    ));

    final received = transaction.swapIncomingSatoshi as int;
    final receivedAsset = satoshiAssets
        .firstWhere((asset) => asset.id == transaction.swapIncomingAssetId);
    final formattedReceived = ref.read(formatterProvider).formatAssetAmount(
          amount: received,
          precision: receivedAsset.precision,
        );
    final receivedText = '$formattedReceived ${receivedAsset.ticker}';
    items.add(AssetTransactionDetailsDataItemUiModel(
      title: AppLocalizations.of(context)!.assetTransactionDetailsReceived,
      value: receivedText,
    )); //0.00003337*0.50739721

    // -----------
    items.add(const AssetTransactionDetailsDividerItemUiModel());

    // Transaction Id
    final transactionId = transaction.txhash;
    if (transactionId != null) {
      items.add(
        AssetTransactionDetailsCopyableItemUiModel(
          title: AppLocalizations.of(context)!
              .assetTransactionDetailsTransactionId,
          value: transactionId,
        ),
      );
    }

    return items;
  }

  Future<List<AssetTransactionDetailsItemUiModel>> _redepositItems(
    BuildContext context,
    TransactionDataArgument arguments,
  ) async {
    final asset = arguments.transactionAsset;
    final transaction = arguments.transaction;

    final items = <AssetTransactionDetailsItemUiModel>[];

    // Swap/Pending/Sep 23, 2021 at 14:31
    final type = AppLocalizations.of(context)!.assetTransactionsTypeRedeposit;
    final showPendingIndicator = asset.isBTC
        ? arguments.confirmationCount < onchainConfirmationBlockCount
        : arguments.confirmationCount < liquidConfirmationBlockCount;
    final date = await formattedDate(context, transaction.createdAtTs);
    items.add(AssetTransactionDetailsHeaderItemUiModel(
      type: type,
      showPendingIndicator: showPendingIndicator,
      date: date,
    ));

    final delivered = transaction.outputs?.first.satoshi as int;
    final formattedDelivered = ref.read(formatterProvider).formatAssetAmount(
          amount: delivered,
          precision: asset.precision,
        );
    final deliveredText =
        '$formattedDelivered ${arguments.satoshiAssets?.first.ticker ?? ''}';
    items.add(AssetTransactionDetailsDataItemUiModel(
      title: AppLocalizations.of(context)!.amount,
      value: transaction.outputs?.first.assetId != null
          ? AppLocalizations.of(context)!.confidental
          : deliveredText,
    ));

    final received = transaction.fee as int;
    final formattedReceived = ref.read(formatterProvider).formatAssetAmount(
          amount: received,
          precision: asset.precision,
        );
    final receivedText = '$formattedReceived ${asset.ticker}';
    items.add(AssetTransactionDetailsDataItemUiModel(
      title: AppLocalizations.of(context)!.fee,
      value: receivedText,
    ));

    // -----------
    items.add(const AssetTransactionDetailsDividerItemUiModel());

    // Transaction Id
    final transactionId = transaction.txhash;
    if (transactionId != null) {
      items.add(
        AssetTransactionDetailsCopyableItemUiModel(
          title: AppLocalizations.of(context)!
              .assetTransactionDetailsTransactionId,
          value: transactionId,
        ),
      );
    }

    return items;
  }

  Future<List<AssetTransactionDetailsItemUiModel>> _outgoingItems(
    BuildContext context,
    TransactionDataArgument arguments,
  ) async {
    final asset = arguments.transactionAsset;
    final transaction = arguments.transaction;
    final feeAsset = arguments.feeAsset;

    final items = <AssetTransactionDetailsItemUiModel>[];

    // Sent/Pending/Sep 23, 2021 at 14:31
    final type = AppLocalizations.of(context)!.assetTransactionsTypeSent;
    final showPendingIndicator = asset.isBTC
        ? arguments.confirmationCount < onchainConfirmationBlockCount
        : arguments.confirmationCount < liquidConfirmationBlockCount;
    final date = await formattedDate(context, transaction.createdAtTs);
    items.add(AssetTransactionDetailsHeaderItemUiModel(
      type: type,
      showPendingIndicator: showPendingIndicator,
      date: date,
    ));

    final amount = transaction.satoshi?[asset.id] as int;
    final formattedAmount = ref.read(formatterProvider).signedFormatAssetAmount(
          amount: amount,
          precision: asset.precision,
        );
    final cryptoAmount = '$formattedAmount ${asset.ticker}';
    items.add(AssetTransactionDetailsDataItemUiModel(
      title: AppLocalizations.of(context)!.amount,
      value: cryptoAmount,
    ));

    final fee = transaction.fee;
    {
      final formattedFee = ref.read(formatterProvider).signedFormatAssetAmount(
            amount: -(fee ?? 0),
            precision: feeAsset.precision,
          );
      final feeText = '$formattedFee ${feeAsset.ticker}';
      items.add(AssetTransactionDetailsDataItemUiModel(
        title: AppLocalizations.of(context)!.fee,
        value: feeText,
      ));
    }

    // My Notes
    final notes = arguments.memo;
    items.add(AssetTransactionDetailsNotesItemUiModel(
      notes: notes,
      onTap: () {},
    ));

    // -----------
    items.add(const AssetTransactionDetailsDividerItemUiModel());

    // Transaction Id
    final transactionId = transaction.txhash;
    if (transactionId != null) {
      items.add(
        AssetTransactionDetailsCopyableItemUiModel(
          title: AppLocalizations.of(context)!
              .assetTransactionDetailsTransactionId,
          value: transactionId,
        ),
      );
    }
    return items;
  }

  Future<List<AssetTransactionDetailsItemUiModel>> _incomingItems(
    BuildContext context,
    TransactionDataArgument arguments,
  ) async {
    final asset = arguments.transactionAsset;
    final transaction = arguments.transaction;

    final items = <AssetTransactionDetailsItemUiModel>[];

    // Received/Pending/Sep 23, 2021 at 14:31
    final type = AppLocalizations.of(context)!.assetTransactionsTypeReceived;
    final showPendingIndicator = asset.isBTC
        ? arguments.confirmationCount < onchainConfirmationBlockCount
        : arguments.confirmationCount < liquidConfirmationBlockCount;
    final date = await formattedDate(context, transaction.createdAtTs);
    items.add(AssetTransactionDetailsHeaderItemUiModel(
      type: type,
      showPendingIndicator: showPendingIndicator,
      date: date,
    ));

    final amount = transaction.satoshi?[asset.id] as int;
    final formattedAmount = ref.read(formatterProvider).formatAssetAmount(
          amount: amount,
          precision: asset.precision,
        );
    final cryptoAmount = '$formattedAmount ${asset.ticker}';
    items.add(AssetTransactionDetailsDataItemUiModel(
      title: AppLocalizations.of(context)!.amount,
      value: cryptoAmount,
    ));

    // My Notes
    final notes = arguments.memo;
    items.add(AssetTransactionDetailsNotesItemUiModel(
      notes: notes,
      onTap: () {},
    ));

    // -----------
    items.add(const AssetTransactionDetailsDividerItemUiModel());

    // Transaction Id
    final transactionId = transaction.txhash;
    if (transactionId != null) {
      items.add(
        AssetTransactionDetailsCopyableItemUiModel(
          title: AppLocalizations.of(context)!
              .assetTransactionDetailsTransactionId,
          value: transactionId,
        ),
      );
    }

    return items;
  }

  Future<String> formattedDate(BuildContext context, int? timestamp) async {
    return timestamp != null
        ? DateFormat(
                'MMM d, yyyy \'${AppLocalizations.of(context)!.assetTransactionDetailsTimeAt}\' HH:mm')
            .format(DateTime.fromMicrosecondsSinceEpoch(timestamp))
        : '';
  }

  Future<void> refresh() async {
    final asset = arg?.$1;
    if (asset != null) {
      ref.invalidate(rawTransactionsProvider(asset));
    }
  }
}

class AssetTransactionDetailsInvalidArgumentsException implements Exception {}

class AssetTransactionDetailsTransactionNotFoundException
    implements Exception {}

class AssetTransactionDetailsProviderUnableToLaunchLinkException
    implements Exception {}
