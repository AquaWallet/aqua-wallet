import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_details_args.freezed.dart';

@freezed
class TransactionDetailsArgs with _$TransactionDetailsArgs {
  const factory TransactionDetailsArgs({
    required String transactionId,
    required Asset asset,
  }) = _TransactionDetailsArgs;
}
