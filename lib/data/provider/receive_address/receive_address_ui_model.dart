import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'receive_address_ui_model.freezed.dart';

@freezed
class ReceiveAddressUiModel with _$ReceiveAddressUiModel {
  const factory ReceiveAddressUiModel.usedAddresses({
    required List<ReceiveUsedAddressItemUiModel> itemUiModels,
  }) = ReceiveUsedAddressUiModel;
  const factory ReceiveAddressUiModel.allAddresses({
    required List<ReceiveAllAddressItemUiModel> itemUiModels,
  }) = ReceiveAllAddressesUiModel;
  const factory ReceiveAddressUiModel.loading() = ReceiveAddressLoadingUiModel;
  const factory ReceiveAddressUiModel.error({
    required Function() buttonAction,
  }) = ReceiveAddressErrorUiModel;
}

@freezed
class ReceiveUsedAddressItemUiModel with _$ReceiveUsedAddressItemUiModel {
  const factory ReceiveUsedAddressItemUiModel({
    required String date,
    required String amount,
    required String network,
    required String transactionId,
    required List<String> addresses,
  }) = _ReceiveUsedAddressItemUiModel;
}

@freezed
class ReceiveAllAddressItemUiModel with _$ReceiveAllAddressItemUiModel {
  const factory ReceiveAllAddressItemUiModel({
    required int txCount,
    required String address,
    required String addressType,
    required String date,
  }) = _ReceiveAllAddressItemUiModel;
}

@freezed
class ReceiveAddressChipsState with _$ReceiveAddressChipsState {
  const factory ReceiveAddressChipsState.used() = ReceiveAddressChipsStateUsed;
  const factory ReceiveAddressChipsState.all() = ReceiveAddressChipsStateAll;
}
