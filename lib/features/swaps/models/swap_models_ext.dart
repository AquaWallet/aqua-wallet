import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:aqua/data/provider/liquid_provider.dart';

//ANCHOR: SwapAsset
extension SwapAssetExt on SwapAsset {
  Asset toAsset() {
    return Asset(
      id: id,
      name: name,
      ticker: ticker,
      logoUrl: getLogoUrl(),
      isDefaultAsset: isDefaultAsset(),
      isLiquid: id ==
          AssetIds.getAssetId(
              AssetType.usdtliquid, LiquidNetworkEnumType.mainnet),
      isLBTC: ticker == AssetExt.lBtcMainnetTicker ||
          ticker == AssetExt.lBtcTestnetTicker,
      isUSDt: isUSDt(),
    );
  }

  bool isUSDt() {
    final usdtAssets = [
      usdtEth.id,
      usdtTrx.id,
      usdtBep.id,
      usdtSol.id,
      usdtPol.id,
      usdtTon.id,
      AssetIds.getAssetId(AssetType.usdtliquid, LiquidNetworkEnumType.mainnet),
    ];
    return usdtAssets.contains(id);
  }

  String getLogoUrl() {
    if (id == AssetIds.btc) return Svgs.btcAsset;
    if (id == AssetIds.lightning) return Svgs.lightningAsset;
    if (isUSDt()) {
      switch (id) {
        case AssetIds.usdtEth:
          return Svgs.ethUsdtAsset;
        case AssetIds.usdtTrx:
          return Svgs.tronUsdtAsset;
        case AssetIds.usdtBep:
          return Svgs.bepUsdtAsset;
        case AssetIds.usdtSol:
          return Svgs.solUsdtAsset;
        case AssetIds.usdtPol:
          return Svgs.polUsdtAsset;
        case AssetIds.usdtTon:
          return Svgs.tonUsdtAsset;
        default:
          if (id ==
              AssetIds.getAssetId(
                  AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)) {
            return Svgs.usdtAsset;
          }
          break;
      }
    }
    return Svgs.unknownAsset;
  }

  bool isDefaultAsset() {
    return ticker == AssetExt.lBtcMainnetTicker ||
        ticker == AssetExt.lBtcTestnetTicker;
  }

  static SwapAsset btc = SwapAsset.fromAsset(Asset.btc());
  static SwapAsset usdtEth = SwapAsset.fromAsset(Asset.usdtEth());
  static SwapAsset usdtTrx = SwapAsset.fromAsset(Asset.usdtTrx());
  static SwapAsset usdtBep = SwapAsset.fromAsset(Asset.usdtBep());
  static SwapAsset usdtSol = SwapAsset.fromAsset(Asset.usdtSol());
  static SwapAsset usdtPol = SwapAsset.fromAsset(Asset.usdtPol());
  static SwapAsset usdtTon = SwapAsset.fromAsset(Asset.usdtTon());
  static SwapAsset usdtLiquid = SwapAsset.fromAsset(Asset.usdtLiquid());
  static SwapAsset lbtc = SwapAsset.fromAsset(Asset.lbtc());

  static SwapAsset fromAsset(Asset asset) {
    return SwapAsset(
      id: asset.id,
      name: asset.name,
      ticker: asset.ticker,
    );
  }

  static SwapAsset fromId(String id) {
    switch (id) {
      case AssetIds.btc:
        return btc;
      case AssetIds.usdtEth:
        return usdtEth;
      case AssetIds.usdtTrx:
        return usdtTrx;
      case AssetIds.usdtBep:
        return usdtBep;
      case AssetIds.usdtSol:
        return usdtSol;
      case AssetIds.usdtPol:
        return usdtPol;
      case AssetIds.usdtTon:
        return usdtTon;
      default:
        if (id ==
            AssetIds.getAssetId(
                AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)) {
          return usdtLiquid;
        } else if (id ==
            AssetIds.getAssetId(
                AssetType.lbtc, LiquidNetworkEnumType.mainnet)) {
          return lbtc;
        } else {
          return SwapAsset(id: id, name: 'Unknown', ticker: 'Unknown');
        }
    }
  }
}

//ANCHOR: SwapFee
extension SwapFeeExtension on SwapFee {
  String displayFee() {
    if (type == SwapFeeType.percentageFee) {
      return '${(value * Decimal.fromInt(100)).toStringAsFixed(2)}%';
    } else {
      switch (currency) {
        case SwapFeeCurrency.usd:
          return '${value.toStringAsFixed(2)} USD';
        case SwapFeeCurrency.sats:
          return '${value.toInt()} sats';
      }
    }
  }
}

//ANCHOR: NetworkFee
extension NetworkFeeExtension on SwapOrder {
  String get displayNetworkFeeForUSDt {
    final fee = settleCoinNetworkFee ?? Decimal.zero;
    return fee.toStringAsFixed(2);
  }

  bool get hasNetworkFee =>
      (settleCoinNetworkFee ?? Decimal.zero) != Decimal.zero;
}

//ANCHOR: SwapOrderStatus
extension SwapOrderStatusExtension on SwapOrderStatus {
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case SwapOrderStatus.unknown:
        return context.loc.unknown;
      case SwapOrderStatus.waiting:
        return context.loc.waiting;
      case SwapOrderStatus.processing:
        return context.loc.processing;
      case SwapOrderStatus.exchanging:
        return context.loc.swapStatusExchanging;
      case SwapOrderStatus.sending:
        return context.loc.sending;
      case SwapOrderStatus.completed:
        return context.loc.completed;
      case SwapOrderStatus.failed:
        return context.loc.failed;
      case SwapOrderStatus.refunding:
        return context.loc.refunding;
      case SwapOrderStatus.refunded:
        return context.loc.refunded;
      case SwapOrderStatus.expired:
        return context.loc.expired;
    }
  }
}

//ANCHOR: SwapServiceType
extension SwapServiceTypeExtension on SwapServiceSource {
  String get displayName {
    switch (this) {
      case SwapServiceSource.sideshift:
        return 'SideShift';
      case SwapServiceSource.changelly:
        return 'Changelly';
    }
  }

  String serviceUrl({String? orderId}) {
    switch (this) {
      case SwapServiceSource.sideshift:
        const baseUrl = 'https://sideshift.ai/';
        return orderId != null ? '$baseUrl?orderId=$orderId' : baseUrl;
      case SwapServiceSource.changelly:
        const baseUrl = 'https://changelly.com';
        return orderId != null
            ? '$baseUrl/faq/submit-a-ticket/?orderid=$orderId'
            : baseUrl;
    }
  }

  bool get needsAmountOnReceive {
    switch (this) {
      case SwapServiceSource.sideshift:
        return false;
      case SwapServiceSource.changelly:
        return true;
    }
  }
}
