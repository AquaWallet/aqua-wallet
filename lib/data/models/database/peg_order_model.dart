import 'dart:convert';

import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/models/sideswap.dart';
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
    @Index() required bool isPegIn,
    required int amount,
    required String statusJson,
    DateTime? createdAt,
  }) = _PegOrderDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory PegOrderDbModel.fromJson(Map<String, dynamic> json) =>
      _$PegOrderDbModelFromJson(json);

  factory PegOrderDbModel.fromStatus({
    required String orderId,
    required bool isPegIn,
    required int amount,
    required SwapPegStatusResult status,
    DateTime? createdAt,
  }) {
    return PegOrderDbModel(
      orderId: orderId,
      isPegIn: isPegIn,
      amount: amount,
      statusJson: jsonEncode(status.toJson()),
      createdAt: createdAt,
    );
  }

  @Ignore()
  SwapPegStatusResult get status =>
      SwapPegStatusResult.fromJson(jsonDecode(statusJson));

  PegOrderDbModel copyWithStatus(SwapPegStatusResult newStatus) {
    return copyWith(statusJson: jsonEncode(newStatus.toJson()));
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
