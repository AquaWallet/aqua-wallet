import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'app_link.freezed.dart';
part 'app_link.g.dart';

@freezed
class AppLink with _$AppLink {
  @JsonSerializable()
  const factory AppLink.swap({
    required String orderId,
    required String sendAsset,
    required int sendAmount,
    required String recvAsset,
    required int recvAmount,
    required String uploadUrl,
  }) = SwapAppLink;

  @JsonSerializable()
  const factory AppLink.samRock({
    required List<String> setupChains,
    required String otp,
    required String uploadUrl,
    @Default(false) bool isMock,
  }) = SamRockAppLink;

  factory AppLink.fromJson(Map<String, dynamic> json) =>
      _$AppLinkFromJson(json);
}
