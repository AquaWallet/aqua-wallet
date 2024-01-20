import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'receive_amount_ui_model.freezed.dart';

@freezed
class ReceiveAmountUiModel with _$ReceiveAmountUiModel {
  const factory ReceiveAmountUiModel.success({
    required Uint8List icon,
    required String name,
    required String ticker,
    required String amount,
    required int precision,
  }) = ReceiveAmountSuccessUiModel;
  const factory ReceiveAmountUiModel.loading() = ReceiveAmountLoadingUiModel;
  const factory ReceiveAmountUiModel.error({
    required String description,
    required String buttonTitle,
    required Function() buttonAction,
  }) = ReceiveAmountErrorUiModel;
}

@freezed
class ReceiveAmountCurrencyButtonUiModel
    with _$ReceiveAmountCurrencyButtonUiModel {
  const factory ReceiveAmountCurrencyButtonUiModel({
    required String title,
    required Color color,
    required Function()? onPressed,
  }) = _ReceiveAmountCurrencyButtonUiModel;
}
