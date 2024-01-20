import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_arguments.freezed.dart';

enum FeeAsset {
  btc('Sats'),
  lbtc('Sats'),
  tetherUsdt('USDt');

  final String name;

  const FeeAsset(this.name);
}

@freezed
class SendAssetArguments with _$SendAssetArguments {
  const factory SendAssetArguments._({
    required Asset asset,
    required String symbol,
    required String network,
    required String address,
    double? userEnteredAmount,
    String? note,
    String? transactionId,

    /// User for external services such as sideshift or boltz
    String? externalServiceTxId,
    double? fee,
    FeeAsset? feeUnit,
    int? timestamp,
    @Default(null) String? recipientAddress,
  }) = _SendAssetArguments;

  factory SendAssetArguments.btc(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Bitcoin',
        symbol: 'BTC',
        address: '',
        recipientAddress: null,
        userEnteredAmount: null,
        fee: null,
        feeUnit: FeeAsset.btc,
      );

  factory SendAssetArguments.lbtc(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Liquid',
        symbol: 'L-BTC',
        address: '',
        feeUnit: FeeAsset.lbtc,
        userEnteredAmount: null,
      );

  factory SendAssetArguments.lightningBtc(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Lightning',
        symbol: 'Sats',
        address: '',
        feeUnit: FeeAsset.lbtc,
        userEnteredAmount: null,
      );

  factory SendAssetArguments.liquidUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Liquid',
        symbol: 'USDt',
        address: '',
        feeUnit: FeeAsset.lbtc,
        userEnteredAmount: null,
      );

  factory SendAssetArguments.ethereumUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Ethereum',
        symbol: 'USDt',
        address: '',
        feeUnit: FeeAsset.lbtc,
        userEnteredAmount: null,
      );

  factory SendAssetArguments.tronUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Tron',
        symbol: 'USDt',
        address: '',
        feeUnit: FeeAsset.lbtc,
        userEnteredAmount: null,
      );

  factory SendAssetArguments.liquid(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Liquid',
        symbol: '',
        address: '',
        feeUnit: FeeAsset.lbtc,
        userEnteredAmount: null,
      );

  factory SendAssetArguments.fromAsset(Asset asset) {
    // have to do these as ifs because we cannot handle it in the case
    // statement below.
    if (asset.isLBTC) {
      return SendAssetArguments.lbtc(asset);
    }
    if (asset.isUsdtLiquid) {
      return SendAssetArguments.liquidUsdt(asset);
    }
    switch (asset.id) {
      case 'btc':
        return SendAssetArguments.btc(asset);
      case 'lightning':
        return SendAssetArguments.lightningBtc(asset);

      case 'eth-usdt':
        return SendAssetArguments.ethereumUsdt(asset);
      case 'trx-usdt':
        return SendAssetArguments.tronUsdt(asset);
      default:
        return SendAssetArguments.liquid(asset);
    }
  }
}
