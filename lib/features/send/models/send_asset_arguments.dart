import 'package:aqua/features/lightning/lnurl_parser/dart_lnurl_parser.dart';
import 'package:aqua/features/send/models/send_asset_start_screen.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:decimal/decimal.dart';
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
  const factory SendAssetArguments._(
      {SendAssetStartScreen? startScreen,
      required Asset asset,
      required String network,
      String? input,
      Decimal? userEnteredAmount,
      LNURLParseResult? lnurlParseResult}) = _SendAssetArguments;

  factory SendAssetArguments.btc(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Bitcoin',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

  factory SendAssetArguments.lbtc(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Liquid',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

  factory SendAssetArguments.lightningBtc(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Lightning',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

  factory SendAssetArguments.liquidUsdt(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Liquid',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

  factory SendAssetArguments.ethereumUsdt(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Ethereum',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

  factory SendAssetArguments.tronUsdt(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Tron',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

  factory SendAssetArguments.liquid(Asset asset) => SendAssetArguments._(
      startScreen: null,
      asset: asset,
      network: 'Liquid',
      input: null,
      userEnteredAmount: null,
      lnurlParseResult: null);

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
