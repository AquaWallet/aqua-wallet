import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_selected_event.freezed.dart';

@freezed
class AssetSelectedEvent with _$AssetSelectedEvent {
  const factory AssetSelectedEvent({
    required String id,
    Asset? asset,
  }) = _AssetSelectedEvent;
}
