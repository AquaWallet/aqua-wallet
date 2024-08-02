import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_details_argument_model.freezed.dart';

@freezed
class TransactionDataArgument with _$TransactionDataArgument {
  const factory TransactionDataArgument({
    required GdkTransaction transaction,
    List<Asset>? satoshiAssets,
    required Asset transactionAsset,
    @Default(0) int confirmationCount,
    required int requiredConfirmationCount,
    required bool isPending,
    required Asset feeAsset,
    String? memo,
    TransactionDbModel? dbTransaction,
  }) = _TransactionDataArgument;
}
