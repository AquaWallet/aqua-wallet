import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'sideshift_order_model.freezed.dart';
part 'sideshift_order_model.g.dart';

@freezed
@Collection(ignore: {'copyWith'})
class SideshiftOrderDbModel with _$SideshiftOrderDbModel {
  const SideshiftOrderDbModel._();

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
    @Enumerated(EnumType.name) OrderType? type,
    String? depositAmount,
    String? settleAmount,
    DateTime? expiresAt,
    @Enumerated(EnumType.name) OrderStatus? status,
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
      type: response.type,
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
}

extension SideshiftOrderDbModelListX on List<SideshiftOrderDbModel> {
  List<SideshiftOrderDbModel> sortByCreated() => sorted((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
}

extension SideshiftOrderFutureListX on Future<List<SideshiftOrderDbModel>> {
  Future<List<SideshiftOrderDbModel>> sortByCreated() async {
    final orders = await this;
    return orders.sortByCreated();
  }
}
