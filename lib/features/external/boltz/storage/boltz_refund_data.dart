import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_refund_data.freezed.dart';
part 'boltz_refund_data.g.dart';

@freezed
class BoltzRefundData with _$BoltzRefundData {
  const factory BoltzRefundData({
    required String id,
    @Default('L-BTC') String asset,
    required String privateKey,
    required String blindingKey,
    required String redeemScript,
    required int timeoutBlockHeight,
  }) = _BoltzRefundData;

  factory BoltzRefundData.fromJson(Map<String, dynamic> json) =>
      _$BoltzRefundDataFromJson(json);
}
