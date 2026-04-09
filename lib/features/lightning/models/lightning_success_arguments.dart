import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ui_components/ui_components.dart';

part 'lightning_success_arguments.freezed.dart';

@freezed
class LightningSuccessArguments with _$LightningSuccessArguments {
  const factory LightningSuccessArguments({
    required int satoshiAmount,
    String? boltzOrderId,
  }) = _LightningSuccessArguments;
}

extension LightningSuccessArgumentsExtension on LightningSuccessArguments {
  TransactionSuccessArguments toTransactionSucessArguments() {
    return TransactionSuccessArguments(
      txId:
          '', // Empty txId for Lightning - will be handled specially in success screen
      network: NetworkType.bitcoin,
      asset: Asset.lightning(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      cryptoUnit: AquaAssetInputUnit.sats,
      amountToReceive: satoshiAmount,
      transactionType: SendTransactionType.send,
      isReceive: true,
      serviceOrderId: boltzOrderId, // Pass Boltz order ID for status monitoring
    );
  }
}
