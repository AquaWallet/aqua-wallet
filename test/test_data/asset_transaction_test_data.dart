import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';

/// Test data factory for creating asset transaction test data
class TestTransactionFactory {
  // Common assets
  static Asset get btcAsset => Asset.btc();
  static Asset get lbtcAsset => Asset.lbtc();
  static Asset get usdtAsset => Asset.usdtLiquid();
  static Asset get lightningAsset => Asset.lightning();
  static List<Asset> get mockAssets => [btcAsset, lbtcAsset, usdtAsset];
  // PEGx EURx assets
  static Asset get eurxAsset => Asset(
        id: '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
        name: 'PEGx EURx',
        ticker: 'EURx',
        logoUrl: 'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg',
        isDefaultAsset: false,
        isRemovable: true,
        isLiquid: true,
      );

  /// Creates a TransactionUiModel with sensible defaults
  static TransactionUiModel transaction({
    String? id,
    DateTime? createdAt,
    String? cryptoAmount,
    Asset? asset,
    Asset? otherAsset,
    GdkTransactionTypeEnum? gdkType,
    TransactionDbModelType? dbType,
    bool isFailed = false,
    Asset? feeForAsset,
    bool isPending = false,
    String? serviceOrderId,
    int? satoshiAmount,
  }) {
    final txId = id ?? 'test_txn_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = createdAt ?? DateTime.now();
    final txAsset = asset ?? btcAsset;

    if (isPending) {
      return TransactionUiModel.pending(
        transactionId: txId,
        createdAt: timestamp,
        cryptoAmount: cryptoAmount ?? '0.001',
        asset: txAsset,
        otherAsset: otherAsset,
        feeForAsset: feeForAsset,
        dbTransaction: _createDbTransaction(
          txhash: txId,
          type: dbType ?? TransactionDbModelType.aquaSend,
          serviceOrderId: serviceOrderId,
          asset: txAsset,
          otherAsset: otherAsset,
        ),
      );
    }

    final gdkTxn = _createGdkTransaction(
      txhash: txId,
      type: gdkType ?? GdkTransactionTypeEnum.incoming,
      timestamp: timestamp,
      asset: txAsset,
      otherAsset: otherAsset,
      satoshiAmount: satoshiAmount,
    );

    return TransactionUiModel.normal(
      createdAt: timestamp,
      cryptoAmount: cryptoAmount ?? '0.001',
      asset: txAsset,
      otherAsset: otherAsset,
      transaction: gdkTxn,
      isFailed: isFailed,
      feeForAsset: feeForAsset,
      dbTransaction: dbType != null
          ? _createDbTransaction(
              txhash: txId,
              type: dbType,
              serviceOrderId: serviceOrderId,
              asset: txAsset,
              otherAsset: otherAsset,
            )
          : null,
    );
  }

  /// Convenience method for swap transactions
  static TransactionUiModel swap({
    String? id,
    Asset? fromAsset,
    Asset? toAsset,
    String? cryptoAmount,
    DateTime? createdAt,
    TransactionDbModelType dbType = TransactionDbModelType.sideswapSwap,
    bool isPending = false,
  }) =>
      transaction(
        id: id,
        createdAt: createdAt,
        cryptoAmount: cryptoAmount ?? '-0.001',
        asset: fromAsset ?? lbtcAsset,
        otherAsset: toAsset ?? usdtAsset,
        gdkType: GdkTransactionTypeEnum.swap,
        dbType: dbType,
        satoshiAmount: -100000,
        serviceOrderId: 'swap_${id ?? 'test'}',
        isPending: isPending,
      );

  static GdkTransaction _createGdkTransaction({
    required String txhash,
    required GdkTransactionTypeEnum type,
    required DateTime timestamp,
    required Asset asset,
    Asset? otherAsset,
    int? satoshiAmount,
  }) {
    final amount = satoshiAmount ?? 100000;

    return GdkTransaction(
      txhash: txhash,
      type: type,
      createdAtTs: timestamp.microsecondsSinceEpoch,
      satoshi: {asset.id: amount},
      swapOutgoingAssetId:
          type == GdkTransactionTypeEnum.swap ? asset.id : null,
      swapIncomingAssetId:
          type == GdkTransactionTypeEnum.swap ? otherAsset?.id : null,
      swapOutgoingSatoshi: type == GdkTransactionTypeEnum.swap ? amount : null,
      swapIncomingSatoshi:
          type == GdkTransactionTypeEnum.swap ? 100000000 : null,
    );
  }

  static TransactionDbModel _createDbTransaction({
    required String txhash,
    required TransactionDbModelType type,
    String? serviceOrderId,
    Asset? asset,
    Asset? otherAsset,
  }) {
    String? assetId;
    if (type == TransactionDbModelType.sideswapSwap && otherAsset != null) {
      assetId = otherAsset.id;
    } else if (asset != null) {
      assetId = asset.id;
    }

    return TransactionDbModel(
      id: 1,
      txhash: txhash,
      type: type,
      serviceOrderId: serviceOrderId,
      assetId: assetId,
    );
  }

  static SatoshiToFiatConversionModel conversion({
    String currencySymbol = '\$',
    String formatted = '50.00',
  }) =>
      SatoshiToFiatConversionModel(
        currencySymbol: currencySymbol,
        decimal: Decimal.parse(formatted),
        formatted: formatted,
        formattedWithCurrency: '$currencySymbol$formatted',
      );
}
