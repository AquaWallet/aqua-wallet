import 'package:freezed_annotation/freezed_annotation.dart';

part 'lightning_success_arguments.freezed.dart';

enum LightningSuccessType { send, receive }

@freezed
class LightningSuccessArguments with _$LightningSuccessArguments {
  const factory LightningSuccessArguments({
    required LightningSuccessType type,
    required int satoshiAmount,
    String? orderId,
  }) = _LightningSuccessArguments;
}
