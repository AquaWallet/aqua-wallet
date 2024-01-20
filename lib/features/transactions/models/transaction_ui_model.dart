import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/providers/transactions_provider.dart';

class TransactionUiModel {
  TransactionUiModel({
    required this.createdAt,
    required this.cryptoAmount,
    required this.icon,
    required this.asset,
    required this.otherAsset,
    required this.transaction,
  });

  final String createdAt;
  final String cryptoAmount;
  final String icon;
  final Asset asset;
  final Asset? otherAsset;
  final GdkTransaction transaction;
}

extension TransactionUiModelX on TransactionUiModel {
  String type(BuildContext context) {
    return switch (transaction.type) {
      GdkTransactionTypeEnum.incoming =>
        AppLocalizations.of(context)!.assetTransactionsTypeReceived,
      GdkTransactionTypeEnum.outgoing =>
        AppLocalizations.of(context)!.assetTransactionsTypeSent,
      GdkTransactionTypeEnum.redeposit =>
        AppLocalizations.of(context)!.assetTransactionsTypeRedeposit,
      GdkTransactionTypeEnum.swap => asset.id == transaction.swapOutgoingAssetId
          ? AppLocalizations.of(context)!
              .assetTransactionsTypeSwapTo(otherAsset?.ticker ?? '')
          : AppLocalizations.of(context)!
              .assetTransactionsTypeSwapFrom(otherAsset?.ticker ?? ''),
      _ => throw AssetTransactionsInvalidTypeException(),
    };
  }
}
