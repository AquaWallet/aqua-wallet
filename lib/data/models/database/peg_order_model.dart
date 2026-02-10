import 'dart:convert';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'peg_order_model.freezed.dart';
part 'peg_order_model.g.dart';

@freezed
@Collection(ignore: {'copyWith', 'status'})
class PegOrderDbModel with _$PegOrderDbModel {
  const PegOrderDbModel._();

  @JsonSerializable()
  const factory PegOrderDbModel({
    @Default(Isar.autoIncrement) int id,
    @JsonKey(required: true, disallowNullValue: true)
    @Index()
    required String orderId,
    @Index() String? walletId,
    @Index() String? txhash,
    @Index() required bool isPegIn,
    required int amount,
    required String statusJson,
    String? depositAddress,
    String? receiveAddress,
    DateTime? createdAt,
  }) = _PegOrderDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory PegOrderDbModel.fromJson(Map<String, dynamic> json) =>
      _$PegOrderDbModelFromJson(json);

  factory PegOrderDbModel.fromStatus({
    required String orderId,
    required String walletId,
    required bool isPegIn,
    required int amount,
    required SwapPegStatusResult status,
    DateTime? createdAt,
  }) {
    return PegOrderDbModel(
      orderId: orderId,
      walletId: walletId,
      isPegIn: isPegIn,
      txhash: status.transactions.firstOrNull?.txHash,
      depositAddress: status.depositAddress,
      receiveAddress: status.receiveAddress,
      amount: amount,
      statusJson: jsonEncode(status.toJson()),
      createdAt: createdAt,
    );
  }

  @Ignore()
  SwapPegStatusResult get status =>
      SwapPegStatusResult.fromJson(jsonDecode(statusJson));

  PegOrderDbModel copyWithStatus(SwapPegStatusResult newStatus) {
    return copyWith(
      statusJson: jsonEncode(newStatus.toJson()),
      txhash: newStatus.transactions.firstOrNull?.txHash ?? txhash,
    );
  }
}

extension PegOrderDbModelListX on List<PegOrderDbModel> {
  List<PegOrderDbModel> sortByCreated() => sorted((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
}

extension PegOrderFutureListX on Future<List<PegOrderDbModel>> {
  Future<List<PegOrderDbModel>> sortByCreated() async {
    final orders = await this;
    return orders.sortByCreated();
  }
}

extension PegOrderX on PegOrderDbModel {
  bool get isPendingConfirmations {
    final orderStatus = status.getConsolidatedStatus();
    final confirmations = orderStatus.detectedConfs ?? 0;
    final requiredConfirmations = orderStatus.totalConfs ?? 999;
    return confirmations < requiredConfirmations;
  }
}
