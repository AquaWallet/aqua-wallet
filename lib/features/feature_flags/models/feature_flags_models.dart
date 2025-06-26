import 'package:aqua/features/shared/shared.dart';
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

@freezed
class ServiceTilesResponse with _$ServiceTilesResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ServiceTilesResponse(
      {required String name, required bool isActive}) = _ServiceTilesResponse;

  factory ServiceTilesResponse.fromJson(Map<String, dynamic> json) =>
      _$ServiceTilesResponseFromJson(json);
}

enum MarketplaceServiceType {
  @JsonValue('buy_bitcoin')
  buyBitcoin,

  @JsonValue('swaps')
  swaps,

  @JsonValue('btc_map')
  btcMap,

  @JsonValue('my_first_bitcoin')
  myFirstBitcoin,

  @JsonValue('dolphin_card')
  debitCard,

  @JsonValue('gift_cards')
  giftCards
}

extension on MarketplaceServiceType {
  String toJson() => _$MarketplaceServiceTypeEnumMap[this]!;
}

MarketplaceServiceType? _marketplaceServiceTypeFromString(String id) {
  return MarketplaceServiceType.values.firstWhereOrNull(
    (e) => e.toJson() == id,
  );
}

@freezed
class MarketplaceServiceAvailability with _$MarketplaceServiceAvailability {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory MarketplaceServiceAvailability({
    required MarketplaceServiceType type,
    required bool isEnabled,
  }) = _MarketplaceServiceAvailability;

  factory MarketplaceServiceAvailability.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceServiceAvailabilityFromJson(json);

  static MarketplaceServiceAvailability? fromResponse(
      ServiceTilesResponse response) {
    final type = _marketplaceServiceTypeFromString(response.name);
    if (type == null) {
      debugPrint('Unknown action id: ${response.name}');
      return null;
    }

    return MarketplaceServiceAvailability(
      type: type,
      isEnabled: response.isActive == true,
    );
  }
}
