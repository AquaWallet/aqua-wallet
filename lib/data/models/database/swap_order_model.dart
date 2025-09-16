import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_order_model.freezed.dart';
part 'swap_order_model.g.dart';

@freezed
@Collection(ignore: {'copyWith'})
class SwapOrderDbModel with _$SwapOrderDbModel {
  const SwapOrderDbModel._();

  @JsonSerializable()
  const factory SwapOrderDbModel({
    @Default(Isar.autoIncrement) int id,
    @JsonKey(required: true, disallowNullValue: true)
    @Index()
    required String orderId,
    required DateTime createdAt,
    required String fromAsset,
    required String toAsset,
    required String depositAddress,
    String? depositExtraId,
    required String settleAddress,
    String? settleExtraId,
    required String depositAmount,
    String? settleAmount,
    @Enumerated(EnumType.name) required SwapFeeType serviceFeeType,
    required String serviceFeeValue,
    @Enumerated(EnumType.name) required SwapFeeCurrency serviceFeeCurrency,
    String? depositCoinNetworkFee,
    String? settleCoinNetworkFee,
    DateTime? expiresAt,
    @Enumerated(EnumType.name) required SwapOrderStatus status,
    @Enumerated(EnumType.name) required SwapOrderType type,
    @Enumerated(EnumType.name) required SwapServiceSource serviceType,
    String? onchainTxHash,
    DateTime? updatedAt,
  }) = _SwapOrderDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory SwapOrderDbModel.fromJson(Map<String, dynamic> json) =>
      _$SwapOrderDbModelFromJson(json);

  factory SwapOrderDbModel.fromSwapOrder(SwapOrder order) {
    return SwapOrderDbModel(
      orderId: order.id,
      createdAt: order.createdAt,
      fromAsset: order.from.ticker,
      toAsset: order.to.ticker,
      depositAddress: order.depositAddress,
      depositExtraId: order.depositExtraId,
      settleAddress: order.settleAddress,
      settleExtraId: order.settleExtraId,
      depositAmount: order.depositAmount.toString(),
      settleAmount: order.settleAmount?.toString(),
      serviceFeeType: order.serviceFee.type,
      serviceFeeValue: order.serviceFee.value.toString(),
      serviceFeeCurrency: order.serviceFee.currency,
      expiresAt: order.expiresAt,
      status: order.status,
      type: order.type,
      serviceType: order.serviceType,
      onchainTxHash: null,
      updatedAt: DateTime.now(),
    );
  }

  SwapOrder toSwapOrder() {
    return SwapOrder(
      createdAt: createdAt,
      id: orderId,
      from: SwapAssetExt.fromId(fromAsset),
      to: SwapAssetExt.fromId(toAsset),
      depositAddress: depositAddress,
      depositExtraId: depositExtraId,
      settleAddress: settleAddress,
      settleExtraId: settleExtraId,
      depositAmount: Decimal.parse(depositAmount),
      settleAmount: settleAmount != null ? Decimal.parse(settleAmount!) : null,
      serviceFee: SwapFee(
        type: serviceFeeType,
        value: Decimal.parse(serviceFeeValue),
        currency: serviceFeeCurrency,
      ),
      depositCoinNetworkFee: depositCoinNetworkFee != null
          ? Decimal.parse(depositCoinNetworkFee!)
          : null,
      settleCoinNetworkFee: settleCoinNetworkFee != null
          ? Decimal.parse(settleCoinNetworkFee!)
          : null,
      expiresAt: expiresAt,
      status: status,
      type: type,
      serviceType: serviceType,
    );
  }
}

extension SwapOrderDbModelListX on List<SwapOrderDbModel> {
  List<SwapOrderDbModel> sortByCreatedAt() => sorted((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });
}

extension SwapOrderFutureListX on Future<List<SwapOrderDbModel>> {
  Future<List<SwapOrderDbModel>> sortByCreatedAt() async {
    final orders = await this;
    return orders.sortByCreatedAt();
  }
}
