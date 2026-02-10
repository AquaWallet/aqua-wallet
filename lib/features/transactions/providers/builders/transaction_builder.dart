import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';

// Base interface for transaction builders
//
// Each builder is responsible for processing a specific type of transaction
// and creating appropriate UI models.
abstract class TransactionUiModelBuilder {
  Future<List<TransactionUiModel>> build(TransactionBuilderArgs args);
}

class TransactionBuilderArgs {
  const TransactionBuilderArgs({
    required this.asset,
    required this.networkTxns,
    required this.localDbTxns,
    required this.availableAssets,
  });

  final Asset asset;
  final List<GdkTransaction> networkTxns;
  final List<TransactionDbModel> localDbTxns;
  final List<Asset> availableAssets;
}
