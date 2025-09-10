import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/send/send.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_up_invoice_state.freezed.dart';

@freezed
class TopUpInvoiceState with _$TopUpInvoiceState {
  const factory TopUpInvoiceState({
    GenerateInvoiceResponse? invoice,
    required SendAssetArguments arguments,
  }) = _TopUpInvoiceState;
}
