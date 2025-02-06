import 'package:aqua/features/sideshift/models/sideshift_order_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift_order.freezed.dart';
part 'sideshift_order.g.dart';

enum SideshiftOrderType {
  @JsonValue('variable')
  variable,
  @JsonValue('fixed')
  fixed,
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
  SideshiftOrderType? get orderType;
  DateTime? get expiresAt;
}

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
    SideshiftOrderType? orderType,
    DateTime? expiresAt,
    required String refundAddress,
    String? quoteId,
    String? depositAmount,
    String? settleAmount,
    SideshiftOrderStatus? status,
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
    SideshiftOrderType? orderType,
    DateTime? expiresAt,
    SideshiftOrderStatus? status,
    String? settleCoinNetworkFee,
  }) = _SideshiftVariableOrderResponse;

  factory SideshiftVariableOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftVariableOrderResponseFromJson(json);
}
