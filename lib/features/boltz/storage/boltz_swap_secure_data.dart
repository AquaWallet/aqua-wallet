import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_swap_secure_data.freezed.dart';
part 'boltz_swap_secure_data.g.dart';

@freezed
class BoltzSwapSecureData with _$BoltzSwapSecureData {
  const factory BoltzSwapSecureData({
    required String privateKeyHex,
    String? preimageHex,
  }) = _BoltzSwapSecureData;

  factory BoltzSwapSecureData.fromJson(Map<String, dynamic> json) =>
      _$BoltzSwapSecureDataFromJson(json);
}
