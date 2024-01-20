import 'package:freezed_annotation/freezed_annotation.dart';

part 'lightning_success_arguments.freezed.dart';

@freezed
class LightningSuccessArguments with _$LightningSuccessArguments {
  const factory LightningSuccessArguments.send({
    required int satoshiAmount,
  }) = _LightningSendSuccessArguments;

  const factory LightningSuccessArguments.receive({
    required int satoshiAmount,
  }) = _LightningReceiveSuccessArguments;
}
