import 'package:coin_cz/data/models/network_amount.dart';
import 'package:coin_cz/features/lightning/lnurl_parser/dart_lnurl_parser.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
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
  const factory SendAssetArguments._({
    required Asset asset,
    required String network,
    SwapPair? swapPair,
    String? input,
    String? externalPrivateKey,
    Decimal? userEnteredAmount,
    NetworkAmount? networkAmount,
    LNURLParseResult? lnurlParseResult,
    SendTransactionType? transactionType,
  }) = _SendAssetArguments;

  factory SendAssetArguments({
    required Asset asset,
    required String network,
    SwapPair? swapPair,
    String? input,
    String? externalPrivateKey,
    Decimal? userEnteredAmount,
    NetworkAmount? networkAmount,
    LNURLParseResult? lnurlParseResult,
    SendTransactionType? transactionType = SendTransactionType.send,
  }) {
    return SendAssetArguments._(
      asset: asset,
      network: network,
      swapPair: swapPair,
      input: input,
      externalPrivateKey: externalPrivateKey,
      userEnteredAmount: userEnteredAmount,
      networkAmount: networkAmount ?? NetworkAmount.zero(asset),
      lnurlParseResult: lnurlParseResult,
      transactionType: transactionType,
    );
  }

  factory SendAssetArguments.btc(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Bitcoin',
        swapPair: null,
        input: null,
        externalPrivateKey: null,
        userEnteredAmount: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.lbtc(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Liquid',
        swapPair: null,
        input: null,
        externalPrivateKey: null,
        userEnteredAmount: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.lightningBtc(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Lightning',
        swapPair: null,
        input: null,
        externalPrivateKey: null,
        userEnteredAmount: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.liquidUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Liquid',
        swapPair: null,
        input: null,
        externalPrivateKey: null,
        userEnteredAmount: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.ethereumUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Ethereum',
        swapPair:
            SwapPair(from: SwapAssetExt.usdtLiquid, to: SwapAssetExt.usdtEth),
        input: null,
        externalPrivateKey: null,
        userEnteredAmount: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.tronUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Tron',
        swapPair:
            SwapPair(from: SwapAssetExt.usdtLiquid, to: SwapAssetExt.usdtTrx),
        input: null,
        externalPrivateKey: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.binanceUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Binance',
        swapPair:
            SwapPair(from: SwapAssetExt.usdtLiquid, to: SwapAssetExt.usdtBep),
        input: null,
        externalPrivateKey: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.solanaUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Solana',
        swapPair:
            SwapPair(from: SwapAssetExt.usdtLiquid, to: SwapAssetExt.usdtSol),
        input: null,
        externalPrivateKey: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.polygonUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Polygon',
        swapPair:
            SwapPair(from: SwapAssetExt.usdtLiquid, to: SwapAssetExt.usdtPol),
        input: null,
        externalPrivateKey: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.tonUsdt(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'TON',
        swapPair:
            SwapPair(from: SwapAssetExt.usdtLiquid, to: SwapAssetExt.usdtTon),
        input: null,
        externalPrivateKey: null,
        lnurlParseResult: null,
      );

  factory SendAssetArguments.liquid(Asset asset) => SendAssetArguments._(
        asset: asset,
        network: 'Liquid',
        input: null,
        userEnteredAmount: null,
        lnurlParseResult: null,
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
      case AssetIds.btc:
        return SendAssetArguments.btc(asset);
      case AssetIds.lightning:
        return SendAssetArguments.lightningBtc(asset);

      case AssetIds.usdtEth:
        return SendAssetArguments.ethereumUsdt(asset);
      case AssetIds.usdtTrx:
        return SendAssetArguments.tronUsdt(asset);
      case AssetIds.usdtBep:
        return SendAssetArguments.binanceUsdt(asset);
      case AssetIds.usdtSol:
        return SendAssetArguments.solanaUsdt(asset);
      case AssetIds.usdtPol:
        return SendAssetArguments.polygonUsdt(asset);
      case AssetIds.usdtTon:
        return SendAssetArguments.tonUsdt(asset);
      default:
        return SendAssetArguments.liquid(asset);
    }
  }
}

extension SendAssetArgumentsX on SendAssetArguments {
  FeeStructureArguments toFeeStructureArgs() {
    if (asset.isBTC || asset.isLiquid || asset.isLightning) {
      return FeeStructureArguments.aquaSend(sendAssetArgs: this);
    }
    return FeeStructureArguments.usdtSwap(
      sendAssetArgs: this,
    );
  }
}
