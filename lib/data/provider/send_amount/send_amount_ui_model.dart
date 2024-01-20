import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'send_amount_ui_model.freezed.dart';

@freezed
class SendAmountUiModel with _$SendAmountUiModel {
  const factory SendAmountUiModel.success({
    required Uint8List icon,
    required String name,
    required String ticker,
    required String amount,
    required int precision,
  }) = SendAmountSuccessUiModel;
  const factory SendAmountUiModel.loading() = SendAmountLoadingUiModel;
  const factory SendAmountUiModel.error({
    required String description,
    required String buttonTitle,
    required Function() buttonAction,
  }) = SendAmountErrorUiModel;
}

@freezed
class SendAmountCurrencyButtonUiModel with _$SendAmountCurrencyButtonUiModel {
  const factory SendAmountCurrencyButtonUiModel({
    required String title,
    required Color color,
    required Function()? onPressed,
  }) = _SendAmountCurrencyButtonUiModel;
}
