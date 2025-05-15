import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags_models.freezed.dart';
part 'feature_flags_models.g.dart';

@freezed
class FeatureFlag with _$FeatureFlag {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory FeatureFlag({
    required int id,
    required bool isActive,
    required String name,
    bool? everyone,
    String? percent,
    required bool testing,
    required bool superusers,
    required bool staff,
    required bool authenticated,
    required String languages,
    required bool rollout,
    required String note,
    required DateTime created,
    required DateTime modified,
    required List<int> groups,
    required List<String> users,
  }) = _FeatureFlag;

  factory FeatureFlag.fromJson(Map<String, dynamic> json) =>
      _$FeatureFlagFromJson(json);
}

@freezed
class SwitchType with _$SwitchType {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SwitchType({
    required int id,
    required bool isActive,
    required String name,
    required bool active,
    required String note,
    required DateTime created,
    required DateTime modified,
  }) = _Switch;

  factory SwitchType.fromJson(Map<String, dynamic> json) =>
      _$SwitchTypeFromJson(json);
}
