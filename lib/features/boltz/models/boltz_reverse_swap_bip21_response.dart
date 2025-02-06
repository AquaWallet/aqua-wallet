import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_reverse_swap_bip21_response.freezed.dart';
part 'boltz_reverse_swap_bip21_response.g.dart';

@freezed
class BoltzReverseSwapBip21Response with _$BoltzReverseSwapBip21Response {
  const factory BoltzReverseSwapBip21Response({
    required String bip21,
    required String signature,
  }) = _BoltzReverseSwapBip21Response;

  factory BoltzReverseSwapBip21Response.fromJson(Map<String, dynamic> json) =>
      _$BoltzReverseSwapBip21ResponseFromJson(json);
}
