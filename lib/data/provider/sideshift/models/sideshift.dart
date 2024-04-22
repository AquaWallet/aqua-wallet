import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift.freezed.dart';
part 'sideshift.g.dart';

enum OrderType {
  @JsonValue('variable')
  variable,
  @JsonValue('fixed')
  fixed,
}

enum OrderStatus {
  @JsonValue('waiting')
  waiting,
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('review')
  review,
  @JsonValue('settling')
  settling,
  @JsonValue('settled')
  settled,
  @JsonValue('refund')
  refund,
  @JsonValue('refunding')
  refunding,
  @JsonValue('refunded')
  refunded,
  @JsonValue('expired')
  expired,
}

extension OrderStatusExtension on OrderStatus {
  String localizedString(BuildContext context) {
    switch (this) {
      case OrderStatus.waiting:
        return context.loc.sideshiftOrderStatusWaiting;
      case OrderStatus.pending:
        return context.loc.sideshiftOrderStatusPending;
      case OrderStatus.processing:
        return context.loc.sideshiftOrderStatusProcessing;
      case OrderStatus.review:
        return context.loc.sideshiftOrderStatusReview;
      case OrderStatus.settling:
        return context.loc.sideshiftOrderStatusSettling;
      case OrderStatus.settled:
        return context.loc.sideshiftOrderStatusSettled;
      case OrderStatus.refund:
        return context.loc.sideshiftOrderStatusRefund;
      case OrderStatus.refunding:
        return context.loc.sideshiftOrderStatusRefunding;
      case OrderStatus.refunded:
        return context.loc.sideshiftOrderStatusRefunded;
      case OrderStatus.expired:
        return context.loc.sideshiftOrderStatusExpired;
      default:
        return context.loc.sideshiftOrderStatusUnknown;
    }
  }

  bool get isPending {
    return this == OrderStatus.waiting ||
        this == OrderStatus.pending ||
        this == OrderStatus.processing ||
        this == OrderStatus.review ||
        this == OrderStatus.settling;
  }

  bool get isFailed {
    return this == OrderStatus.refund ||
        this == OrderStatus.refunding ||
        this == OrderStatus.refunded;
  }

  bool get isSuccess {
    return this == OrderStatus.settled;
  }

  bool get isFinal {
    return this == OrderStatus.refunded || this == OrderStatus.settled;
  }
}

@freezed
class SideshiftAssetResponse with _$SideshiftAssetResponse {
  factory SideshiftAssetResponse({
    required String coin,
    required List<String> networks,
    required String name,
    bool? hasMemo,
  }) = _SideshiftAssetResponse;

  factory SideshiftAssetResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftAssetResponseFromJson(json);
}

@freezed
class SideshiftAsset with _$SideshiftAsset {
  factory SideshiftAsset({
    required String id,
    required String coin,
    required String network,
    required String name,
    bool? hasMemo,
  }) = _SideshiftAsset;

  /// Create from a SideshiftAssetResponse
  factory SideshiftAsset.create(
    SideshiftAssetResponse response, {
    required String network,
  }) {
    return SideshiftAsset(
      id: '${response.coin.toLowerCase()}-${network.toLowerCase()}',
      coin: response.coin,
      network: network,
      name: response.name,
      hasMemo: response.hasMemo,
    );
  }

  /// Factory instances for USDT coins
  factory SideshiftAsset.usdtEth() => SideshiftAsset(
        id: 'usdt-ethereum',
        coin: 'USDT',
        network: 'ethereum',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtTron() => SideshiftAsset(
        id: 'usdt-tron',
        coin: 'USDT',
        network: 'tron',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtLiquid() => SideshiftAsset(
        id: 'usdt-liquid',
        coin: 'USDT',
        network: 'liquid',
        name: 'Tether',
      );
}

@freezed
class SideshiftAssetPair with _$SideshiftAssetPair {
  const factory SideshiftAssetPair({
    required SideshiftAsset from,
    required SideshiftAsset to,
  }) = _SideshiftAssetPair;

  // Factory methods for predefined pairs
  factory SideshiftAssetPair.fromUsdtLiquidToUsdtEth() => SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(), to: SideshiftAsset.usdtEth());

  factory SideshiftAssetPair.fromUsdtLiquidToUsdtTron() => SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(), to: SideshiftAsset.usdtTron());

  factory SideshiftAssetPair.fromUsdtEthToUsdtLiquid() => SideshiftAssetPair(
      from: SideshiftAsset.usdtEth(), to: SideshiftAsset.usdtLiquid());

  factory SideshiftAssetPair.fromUsdtTronToUsdtLiquid() => SideshiftAssetPair(
      from: SideshiftAsset.usdtTron(), to: SideshiftAsset.usdtLiquid());
}

@freezed
class SideShiftAssetPairInfo with _$SideShiftAssetPairInfo {
  const factory SideShiftAssetPairInfo({
    required String rate,
    required String min,
    required String max,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
  }) = _SideShiftAssetPairInfo;

  factory SideShiftAssetPairInfo.fromJson(Map<String, dynamic> json) =>
      _$SideShiftAssetPairInfoFromJson(json);
}

// Permissions Response

@freezed
class SideshiftPermissionsResponse with _$SideshiftPermissionsResponse {
  factory SideshiftPermissionsResponse({
    String? createdAt,
    required bool createShift,
  }) = _SideshiftPermissionsResponse;

  factory SideshiftPermissionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftPermissionsResponseFromJson(json);
}

// Fixed Rate Quote

@freezed
class SideshiftQuoteRequest with _$SideshiftQuoteRequest {
  factory SideshiftQuoteRequest({
    String? depositCoin,
    String? depositNetwork,
    String? settleCoin,
    String? settleNetwork,
    String? depositAmount,
    String? settleAmount,
    String? affiliateId,
    String? commissionRate,
  }) = _SideshiftQuoteRequest;

  factory SideshiftQuoteRequest.fromJson(Map<String, dynamic> json) =>
      _$SideshiftQuoteRequestFromJson(json);
}

@freezed
class SideshiftQuoteResponse with _$SideshiftQuoteResponse {
  factory SideshiftQuoteResponse({
    required String id,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    DateTime? expiresAt,
    String? depositAmount,
    String? settleAmount,
    String? rate,
    String? affiliateId,
  }) = _SideshiftQuoteResponse;

  factory SideshiftQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftQuoteResponseFromJson(json);
}

// Fixed Rate Order

@freezed
class SideshiftFixedOrderRequest with _$SideshiftFixedOrderRequest {
  factory SideshiftFixedOrderRequest({
    String? settleAddress,
    String? affiliateId,
    String? quoteId,
    String? refundAddress,
  }) = _SideshiftFixedOrderRequest;

  factory SideshiftFixedOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$SideshiftFixedOrderRequestFromJson(json);
}

abstract class SideshiftOrder {
  String? get id;
  DateTime? get createdAt;
  String? get depositCoin;
  String? get settleCoin;
  String? get depositNetwork;
  String? get settleNetwork;
  String? get depositAddress;
  String? get settleAddress;
  String? get depositMin;
  String? get depositMax;
  OrderType? get type;
  DateTime? get expiresAt;
}

@freezed
class SideshiftFixedOrderResponse
    with _$SideshiftFixedOrderResponse
    implements SideshiftOrder {
  const factory SideshiftFixedOrderResponse({
    String? id,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    String? depositAddress,
    String? settleAddress,
    String? depositMin,
    String? depositMax,
    OrderType? type,
    DateTime? expiresAt,
    required String refundAddress,
    String? quoteId,
    String? depositAmount,
    String? settleAmount,
    OrderStatus? status,
    DateTime? updatedAt,
    String? rate,
  }) = _SideshiftFixedOrderResponse;

  factory SideshiftFixedOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftFixedOrderResponseFromJson(json);
}

@freezed
class SideshiftVariableOrderRequest with _$SideshiftVariableOrderRequest {
  factory SideshiftVariableOrderRequest({
    String? settleAddress,
    String? refundAddress,
    String? affiliateId,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    dynamic settleNetwork,
    String? commissionRate,
  }) = _SideshiftVariableOrderRequest;

  factory SideshiftVariableOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$SideshiftVariableOrderRequestFromJson(json);
}

@freezed
class SideshiftVariableOrderResponse
    with _$SideshiftVariableOrderResponse
    implements SideshiftOrder {
  const factory SideshiftVariableOrderResponse({
    String? id,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    String? depositAddress,
    String? settleAddress,
    String? depositMin,
    String? depositMax,
    OrderType? type,
    DateTime? expiresAt,
    String? status,
    String? settleCoinNetworkFee,
  }) = _SideshiftVariableOrderResponse;

  factory SideshiftVariableOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftVariableOrderResponseFromJson(json);
}

@freezed
class SideshiftOrderStatusResponse with _$SideshiftOrderStatusResponse {
  factory SideshiftOrderStatusResponse({
    String? id,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    String? depositAddress,
    String? settleAddress,
    String? depositMin,
    String? depositMax,
    OrderType? type,
    String? depositAmount,
    String? settleAmount,
    DateTime? expiresAt,
    OrderStatus? status,
    DateTime? updatedAt,
    String? depositHash,
    String? settleHash,
    DateTime? depositReceivedAt,
    String? rate,

    /// The onchain tx hash for the deposit
    String? onchainTxHash,
  }) = _SideshiftOrderStatusResponse;

  factory SideshiftOrderStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftOrderStatusResponseFromJson(json);
}
