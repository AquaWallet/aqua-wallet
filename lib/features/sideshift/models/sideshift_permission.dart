import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift_permission.freezed.dart';
part 'sideshift_permission.g.dart';

@freezed
class SideshiftPermissionsResponse with _$SideshiftPermissionsResponse {
  factory SideshiftPermissionsResponse({
    String? createdAt,
    required bool createShift,
  }) = _SideshiftPermissionsResponse;

  factory SideshiftPermissionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftPermissionsResponseFromJson(json);
}
