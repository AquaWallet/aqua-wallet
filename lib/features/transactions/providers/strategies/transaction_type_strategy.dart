import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

// Strategy pattern for handling different transaction types.
//
// Each transaction type (peg, swap, normal) has different rules for
// creating UI models and determining visibility. Services are injected
// via constructor, transaction data is passed as arguments.
abstract class TransactionUiModelCreator {
  const TransactionUiModelCreator({
    required this.ref,
    required this.formatter,
    required this.assetResolutionService,
    required this.failureService,
    required this.confirmationService,
    required this.appLocalizations,
  });

  final Ref ref;
  final FormatService formatter;
  final AssetResolutionService assetResolutionService;
  final TxnFailureService failureService;
  final ConfirmationService confirmationService;
  final AppLocalizations appLocalizations;

  TransactionUiModel? createPendingListItems(
    TransactionStrategyArgs args,
  );

  TransactionUiModel? createConfirmedListItems(
    TransactionStrategyArgs args,
  );

  Future<AssetTransactionDetailsUiModel?> createPendingDetails(
    TransactionDetailsStrategyArgs args,
  );

  Future<AssetTransactionDetailsUiModel?> createConfirmedDetails(
    TransactionDetailsStrategyArgs args,
  );

  DateTime? getCreatedAt(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    return dbTxn?.ghostTxnCreatedAt ??
        (networkTxn != null
            ? DateTime.fromMicrosecondsSinceEpoch(networkTxn.createdAtTs!)
            : null);
  }

  // Determines if this transaction should appear on the current asset page
  // Has access to all transaction data (db + network) for proper filtering
  bool shouldShowTransactionForAsset(TransactionStrategyArgs args);

  // Creates the formatted crypto amount string for confirmed transactions
  String? getCryptoAmountForNormal(TransactionStrategyArgs args);

  // Creates the formatted crypto amount string for pending transactions
  //
  //NOTE - The distinction between crypto amount for confirmed and pending type
  //is that the later has to find the value from the DB transaction.
  String? getCryptoAmountForPending(TransactionStrategyArgs args);

  // Returns the other asset involved in the transaction
  //
  // For swaps/pegs: returns the counterparty asset
  // For normal transactions: returns null
  Asset? getOtherAsset(TransactionStrategyArgs args);

  String formatDate(int? timestamp) {
    return timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).formatFullDateTime
        : '';
  }

  Asset getFeeAsset(TransactionDetailsStrategyArgs args) {
    final feeAssetId = args.dbTransaction?.feeAssetId;
    if (feeAssetId == null) {
      return args.asset;
    }
    return args.availableAssets.firstWhereOrNull((a) => a.id == feeAssetId) ??
        args.asset;
  }

  String computeBlindingUrl(GdkTransaction? transaction, Asset asset) {
    if (transaction == null || !asset.isLiquid) {
      return '';
    }

    final blindingStrings = <String>[];

    // Extract blinding info from inputs
    if (transaction.inputs?.isNotEmpty ?? false) {
      for (final input in transaction.inputs!) {
        if (input.amountBlinder != null && input.assetBlinder != null) {
          blindingStrings.add(
            '${input.satoshi},${input.assetId},${input.amountBlinder},${input.assetBlinder}',
          );
        }
      }
    }

    // Extract blinding info from outputs
    if (transaction.outputs?.isNotEmpty ?? false) {
      for (final output in transaction.outputs!) {
        if (output.amountBlinder != null && output.assetBlinder != null) {
          blindingStrings.add(
            '${output.satoshi},${output.assetId},${output.amountBlinder},${output.assetBlinder}',
          );
        }
      }
    }

    return blindingStrings.isNotEmpty
        ? '${transaction.txhash}#blinded=${blindingStrings.join(',')}'
        : '';
  }

  String convertToFiat(Asset asset, int satoshiAmount) {
    final conversion = ref.read(conversionProvider((asset, satoshiAmount)));
    return conversion?.formattedWithCurrency ?? '';
  }

  // Calculates the fiat amount display string using historical exchange rate
  // stored in the database at the time of transaction execution.
  //
  // This is used to display "Value at Time" on transaction detail pages.
  // The currency format used is the one that was active at transaction time,
  // not the user's current currency setting.
  //
  // Expected usage is for sats-based assets (BTC, L-BTC, Lightning).
  String? calculateFiatAmountAtExecutionDisplay(
      TransactionDbModel? dbTransaction, int satoshiAmount, Asset asset) {
    final rate = dbTransaction?.exchangeRateAtExecution;
    final currencyCode = dbTransaction?.currencyAtExecution;

    if (rate == null || currencyCode == null || !asset.isSatsAsset) {
      return null;
    }

    final amountInBtc = satoshiAmount.abs() / satsPerBtc;
    final fiatValue = amountInBtc * rate;
    final currency =
        FiatCurrency.values.firstWhereOrNull((c) => c.value == currencyCode);

    // If we can't find the currency format, fall back to default formatting
    // and append the currency code
    if (currency == null) {
      final formatted = formatter.formatFiatAmount(
        amount: Decimal.parse(fiatValue.toStringAsFixed(2)),
        withSymbol: false,
      );
      return '$formatted $currencyCode';
    }

    return formatter.formatFiatAmount(
      amount: Decimal.parse(fiatValue.toStringAsFixed(2)),
      specOverride: currency.format,
      withSymbol: true,
    );
  }
}

class TransactionStrategyArgs {
  const TransactionStrategyArgs({
    required this.asset,
    required this.availableAssets,
    this.dbTransaction,
    this.networkTransaction,
  });

  final Asset asset;
  final List<Asset> availableAssets;
  final TransactionDbModel? dbTransaction;
  final GdkTransaction? networkTransaction;
}

class TransactionDetailsStrategyArgs {
  const TransactionDetailsStrategyArgs({
    required this.asset,
    required this.availableAssets,
    this.dbTransaction,
    this.networkTransaction,
  });

  final Asset asset;
  final List<Asset> availableAssets;
  final TransactionDbModel? dbTransaction;
  final GdkTransaction? networkTransaction;
}

extension TransactionDetailsStrategyArgsX on TransactionDetailsStrategyArgs {
  Asset? get feeForAsset {
    if (networkTransaction == null) {
      return null;
    }

    final deliveredAssetId = networkTransaction!.getDeliverAssetId(asset);
    if (deliveredAssetId == null) {
      return null;
    }

    return availableAssets.firstWhereOrNull((a) => a.id == deliveredAssetId);
  }
}
