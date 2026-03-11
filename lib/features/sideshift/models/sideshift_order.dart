import 'package:aqua/features/sideshift/models/sideshift_order_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'sideshift_order.freezed.dart';
part 'sideshift_order.g.dart';

enum SideshiftOrderType {
  @JsonValue('variable')
  variable,
  @JsonValue('fixed')
  fixed,
}

abstract class SideshiftOrder {
  String get id;
  DateTime get createdAt;
  String get depositCoin;
  String get settleCoin;
  String get depositNetwork;
  String get settleNetwork;
  String get depositAddress;
  String get settleAddress;
  Decimal get depositMin;
  Decimal get depositMax;
  SideshiftOrderType get type;
  DateTime get expiresAt;
}

@freezed
class SideshiftFixedOrderRequest with _$SideshiftFixedOrderRequest {
  factory SideshiftFixedOrderRequest({
    required String settleAddress,
    String? settleMemo,
    required String affiliateId,
    required String quoteId,
    String? refundAddress,
    String? refundMemo,
    String? externalId,
  }) = _SideshiftFixedOrderRequest;

  factory SideshiftFixedOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$SideshiftFixedOrderRequestFromJson(json);
}

@freezed
class SideshiftFixedOrderResponse
    with _$SideshiftFixedOrderResponse
    implements SideshiftOrder {
  const factory SideshiftFixedOrderResponse({
    required String id,
    required DateTime createdAt,
    required String depositCoin,
    required String settleCoin,
    required String depositNetwork,
    required String settleNetwork,
    required String depositAddress,
    String? depositMemo,
    required String settleAddress,
    String? settleMemo,
    required Decimal depositMin,
    required Decimal depositMax,
    String? refundAddress,
    String? refundMemo,
    required SideshiftOrderType type,
    required String quoteId,
    required Decimal depositAmount,
    required Decimal settleAmount,
    required DateTime expiresAt,
    required SideshiftOrderStatus status,
    String? averageShiftSeconds,
    String? externalId,
    required String rate,
  }) = _SideshiftFixedOrderResponse;

  factory SideshiftFixedOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftFixedOrderResponseFromJson(json);
}

@freezed
class SideshiftVariableOrderRequest with _$SideshiftVariableOrderRequest {
  factory SideshiftVariableOrderRequest({
    required String settleAddress,
    String? settleMemo,
    String? refundAddress,
    String? refundMemo,
    required String depositCoin,
    required String settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    required String affiliateId,
    String? externalId,
  }) = _SideshiftVariableOrderRequest;

  factory SideshiftVariableOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$SideshiftVariableOrderRequestFromJson(json);
}

@freezed
class SideshiftVariableOrderResponse
    with _$SideshiftVariableOrderResponse
    implements SideshiftOrder {
  const factory SideshiftVariableOrderResponse({
    required String id,
    required DateTime createdAt,
    required String depositCoin,
    required String settleCoin,
    required String depositNetwork,
    required String settleNetwork,
    required String depositAddress,
    String? depositMemo,
    required String settleAddress,
    String? settleMemo,
    required Decimal depositMin,
    required Decimal depositMax,
    String? refundAddress,
    String? refundMemo,
    required SideshiftOrderType type,
    required DateTime expiresAt,
    required SideshiftOrderStatus status,
    String? averageShiftSeconds,
    String? externalId,
    required Decimal settleCoinNetworkFee,
    required String networkFeeUsd,
  }) = _SideshiftVariableOrderResponse;

  factory SideshiftVariableOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftVariableOrderResponseFromJson(json);
}
