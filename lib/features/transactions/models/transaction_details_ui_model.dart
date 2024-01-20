import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_details_ui_model.freezed.dart';

@freezed
class AssetTransactionDetailsUiModel with _$AssetTransactionDetailsUiModel {
  const factory AssetTransactionDetailsUiModel({
    required List<AssetTransactionDetailsItemUiModel> items,
  }) = _AssetTransactionDetailsUiModel;
}

@freezed
class AssetTransactionDetailsItemUiModel
    with _$AssetTransactionDetailsItemUiModel {
  const factory AssetTransactionDetailsItemUiModel.header({
    required String type,
    required bool showPendingIndicator,
    required String date,
  }) = AssetTransactionDetailsHeaderItemUiModel;
  const factory AssetTransactionDetailsItemUiModel.data({
    required String title,
    required String value,
  }) = AssetTransactionDetailsDataItemUiModel;
  const factory AssetTransactionDetailsItemUiModel.notes({
    required String? notes,
    required Function() onTap,
  }) = AssetTransactionDetailsNotesItemUiModel;
  const factory AssetTransactionDetailsItemUiModel.divider() =
      AssetTransactionDetailsDividerItemUiModel;
  const factory AssetTransactionDetailsItemUiModel.copyableData({
    required String title,
    required String value,
  }) = AssetTransactionDetailsCopyableItemUiModel;
}
