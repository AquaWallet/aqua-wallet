import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'asset_details_item_ui_model.freezed.dart';

@freezed
class AssetDetailsItemUiModel with _$AssetDetailsItemUiModel {
  const factory AssetDetailsItemUiModel.header({
    required Uint8List icon,
    required String name,
    required String ticker,
  }) = AssetDetailsHeaderItemUiModel;
  const factory AssetDetailsItemUiModel.issuer({
    required String issuer,
  }) = AssetDetailsIssuerItemUiModel;
  const factory AssetDetailsItemUiModel.id({
    required String id,
  }) = AssetDetailsIdItemUiModel;
  const factory AssetDetailsItemUiModel.intro({
    required String intro,
  }) = AssetDetailsIntroItemUiModel;
  const factory AssetDetailsItemUiModel.loading() =
      AssetDetailsLoadingItemUiModel;
  const factory AssetDetailsItemUiModel.error({
    required String buttonTitle,
    required Function() buttonAction,
  }) = AssetDetailsErrorItemUiModel;
}
