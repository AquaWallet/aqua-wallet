import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_transaction.freezed.dart';
part 'boltz_transaction.g.dart';

@freezed
class BoltzTransaction with _$BoltzTransaction {
  const factory BoltzTransaction({
    required String id,
    final String? hex,
    final int? eta,
    final bool? zeroConfRejected,
  }) = _BoltzTransaction;

  factory BoltzTransaction.fromJson(Map<String, dynamic> json) =>
      _$BoltzTransactionFromJson(json);
}
