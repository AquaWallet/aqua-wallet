import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

class TransactionDataArgument {
  final GdkTransaction transaction;
  final List<Asset>? satoshiAssets;
  final Asset transactionAsset;
  final int confirmationCount;
  final Asset feeAsset;
  final String? memo;

  TransactionDataArgument({
    required this.transaction,
    this.satoshiAssets,
    required this.transactionAsset,
    this.confirmationCount = 0,
    required this.feeAsset,
    this.memo,
  });

  TransactionDataArgument copyWith({
    GdkTransaction? transaction,
    List<Asset>? satoshiAssets,
    Asset? transactionAsset,
    int? confirmationCount,
    Asset? feeAsset,
    String? memo,
  }) {
    return TransactionDataArgument(
      transaction: transaction ?? this.transaction,
      satoshiAssets: satoshiAssets ?? this.satoshiAssets,
      transactionAsset: transactionAsset ?? this.transactionAsset,
      confirmationCount: confirmationCount ?? this.confirmationCount,
      feeAsset: feeAsset ?? this.feeAsset,
      memo: memo ?? this.memo,
    );
  }

  @override
  String toString() {
    return 'TransactionDataArgument(transaction: $transaction, satoshiAssets: $satoshiAssets, transactionAsset: $transactionAsset, confirmationCount: $confirmationCount, feeAsset: $feeAsset)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is TransactionDataArgument &&
        other.transaction == transaction &&
        listEquals(other.satoshiAssets, satoshiAssets) &&
        other.transactionAsset == transactionAsset &&
        other.confirmationCount == confirmationCount &&
        other.feeAsset == feeAsset &&
        other.memo == memo;
  }

  @override
  int get hashCode {
    return transaction.hashCode ^
        satoshiAssets.hashCode ^
        transactionAsset.hashCode ^
        confirmationCount.hashCode ^
        feeAsset.hashCode ^
        memo.hashCode;
  }
}
