import 'package:aqua/features/shared/shared.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ui_components/components/modal_sheet/modal_sheet.dart';

part 'custom_alert_dialog_ui_model.freezed.dart';

@freezed
class CustomAlertDialogUiModel with _$CustomAlertDialogUiModel {
  const factory CustomAlertDialogUiModel({
    required String title,
    required String subtitle,
    required String buttonTitle,
    required VoidCallback onButtonPressed,
    String? secondaryButtonTitle,
    VoidCallback? onSecondaryButtonPressed,
    Widget? content,
    AquaModalSheetVariant? iconVariant,
    Widget? icon,
  }) = _CustomAlertDialogUiModel;
}
