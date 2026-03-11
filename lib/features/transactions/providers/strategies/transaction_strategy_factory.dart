import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionUiModelsFactoryProvider =
    Provider.autoDispose(TransactionStrategyFactory.new);

// Factory for creating TransactionTypeStrategy instances
//
// This factory reads strategy providers and creates appropriate strategies
// based on transaction types, eliminating the need for manual instantiation.
class TransactionStrategyFactory {
  const TransactionStrategyFactory(this.ref);

  final Ref ref;

  TransactionUiModelCreator create({
    TransactionDbModel? dbTransaction,
    GdkTransaction? networkTransaction,
    Asset? asset,
  }) {
    if (dbTransaction != null) {
      return switch (dbTransaction) {
        // Peg transactions (BTC <-> LBTC via Sideswap)
        _ when dbTransaction.isPeg => ref.read(pegTransactionUiModelsProvider),
        // Lightning transactions (via Boltz) - includes all Boltz types
        _ when dbTransaction.isBoltz =>
          ref.read(lightningTransactionUiModelsProvider),
        // Sideswap swap transactions (Liquid DEX)
        _ when dbTransaction.isSwap =>
          ref.read(sideswapSwapTransactionUiModelsProvider),
        // Alt USDt swap transactions (via Sideshift/Changelly)
        _ when dbTransaction.isUSDtSwap =>
          ref.read(altUsdtTransactionUiModelsProvider),
        // Normal Aqua transactions (sends, receives)
        _ => ref.read(aquaTransactionUiModelsProvider),
      };
    }

    // Use network transaction type
    if (networkTransaction != null) {
      return networkTransaction.type == GdkTransactionTypeEnum.swap
          ? ref.read(sideswapSwapTransactionUiModelsProvider)
          : ref.read(aquaTransactionUiModelsProvider);
    }

    // Default to Aqua strategy
    return ref.read(aquaTransactionUiModelsProvider);
  }
}
