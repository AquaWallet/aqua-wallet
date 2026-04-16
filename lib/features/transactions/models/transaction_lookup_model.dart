import 'package:aqua/data/data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_lookup_model.freezed.dart';

@freezed
class TransactionLookupModel with _$TransactionLookupModel {
  const factory TransactionLookupModel({
    required String assetId,
    required GdkTransaction gdkTransaction,
  }) = _TransactionLookupModel;
}
