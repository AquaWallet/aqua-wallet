import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'custom_alert_dialog_ui_model.freezed.dart';

@freezed
class CustomAlertDialogUiModel with _$CustomAlertDialogUiModel {
  const factory CustomAlertDialogUiModel({
    required String title,
    required String subtitle,
    required String buttonTitle,
    required Function() onButtonPressed,
  }) = _CustomAlertDialogUiModel;
}
