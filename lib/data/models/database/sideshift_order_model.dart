import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/models/sideshift_order_ext.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'sideshift_order_model.freezed.dart';
part 'sideshift_order_model.g.dart';

@Deprecated(
    'Use SwapOrderDbModel instead. This class will be removed in a future version.')
@freezed
@Collection(ignore: {'copyWith'})
class SideshiftOrderDbModel with _$SideshiftOrderDbModel {
  const SideshiftOrderDbModel._();

  @Deprecated(
      'Use SwapOrderDbModel instead. This class will be removed in a future version.')
  @JsonSerializable()
  const factory SideshiftOrderDbModel({
    @Default(Isar.autoIncrement) int id,
    @JsonKey(required: true, disallowNullValue: true)
    @Index()
    required String orderId,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    String? depositAddress,
    String? settleAddress,
    String? depositMin,
    String? depositMax,
    @Enumerated(EnumType.name) SideshiftOrderType? type,
    String? depositAmount,
    String? settleAmount,
    DateTime? expiresAt,
    @Enumerated(EnumType.name) SideshiftOrderStatus? status,
    DateTime? updatedAt,
    String? depositHash,
    String? settleHash,
    DateTime? depositReceivedAt,
    String? rate,
    String? onchainTxHash,
  }) = _SideshiftOrderDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory SideshiftOrderDbModel.fromJson(Map<String, dynamic> json) =>
      _$SideshiftOrderDbModelFromJson(json);

  factory SideshiftOrderDbModel.fromSideshiftOrderResponse(
    SideshiftOrderStatusResponse response,
  ) {
    return SideshiftOrderDbModel(
      orderId: response.id!,
      createdAt: response.createdAt,
      depositCoin: response.depositCoin,
      settleCoin: response.settleCoin,
      depositNetwork: response.depositNetwork,
      settleNetwork: response.settleNetwork,
      depositAddress: response.depositAddress,
      settleAddress: response.settleAddress,
      depositMin: response.depositMin,
      depositMax: response.depositMax,
      type: response.orderType,
      depositAmount: response.depositAmount,
      settleAmount: response.settleAmount,
      expiresAt: response.expiresAt,
      status: response.status,
      updatedAt: response.updatedAt,
      depositHash: response.depositHash,
      settleHash: response.settleHash,
      depositReceivedAt: response.depositReceivedAt,
      rate: response.rate,
      onchainTxHash: response.onchainTxHash,
    );
  }

  @Deprecated('Use SwapOrderDbModel.fromSwapOrder() instead.')
  static SideshiftOrderDbModel fromSwapOrder(SwapOrder swapOrder) {
    return SideshiftOrderDbModel(
      orderId: swapOrder.id,
      createdAt: swapOrder.createdAt,
      depositCoin: swapOrder.from.ticker,
      settleCoin: swapOrder.to.ticker,
      depositNetwork: SideshiftAssetExt.getNetworkString(swapOrder.from.id),
      settleNetwork: SideshiftAssetExt.getNetworkString(swapOrder.to.id),
      depositAddress: swapOrder.depositAddress,
      settleAddress: swapOrder.settleAddress,
      depositMin: null,
      depositMax: null,
      type: SideshiftOrderTypeExt.fromSwapOrderType(swapOrder.type),
      depositAmount: swapOrder.depositAmount.toString(),
      settleAmount: swapOrder.settleAmount?.toString(),
      expiresAt: swapOrder.expiresAt,
      status: SideshiftOrderStatusExt.fromSwapOrderStatus(swapOrder.status),
      updatedAt: DateTime.now(),
    );
  }
}

@Deprecated('Use SwapOrderDbModelListX instead.')
extension SideshiftOrderDbModelListX on List<SideshiftOrderDbModel> {
  List<SideshiftOrderDbModel> sortByCreated() => sorted((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
}

@Deprecated('Use SwapOrderFutureListX instead.')
extension SideshiftOrderFutureListX on Future<List<SideshiftOrderDbModel>> {
  Future<List<SideshiftOrderDbModel>> sortByCreated() async {
    final orders = await this;
    return orders.sortByCreated();
  }
}
