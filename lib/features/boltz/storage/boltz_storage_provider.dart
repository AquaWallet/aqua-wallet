import 'dart:async';
import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/models/boltz_swap_status.dart';
import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.boltzStorage);

const kBoltzBoxName = 'boltz';

//ANCHOR - Public-facing Boltz Orders Storage Notifier

final boltzStorageProvider =
    AsyncNotifierProvider<BoltzSwapStorageNotifier, List<BoltzSwapDbModel>>(
        BoltzSwapStorageNotifier.new);

abstract class BoltzSwapStorage {
  Future<void> save(BoltzSwapDbModel model);
  Future<void> delete(String boltzId);
  Future<void> clear();
  Future<void> saveBoltzSwapResponse({
    required TransactionDbModel txnDbModel,
    required BoltzSwapDbModel swapDbModel,
    required KeyPair keys,
    required PreImage preimage,
  });
  Future<void> updateSubmarineOnBroadcast({
    required String boltzId,
    required String txId,
  });
  Future<void> updateReverseSwapClaim({
    required String boltzId,
    required String claimTxId,
    required String receiveAddress,
    required int outAmount,
    required int fee,
  });
  Future<void> updateRefundTxId({
    required String boltzId,
    required String txId,
  });
  Future<void> updateBoltzSwapStatus({
    required String boltzId,
    required BoltzSwapStatus status,
  });
  Future<LbtcLnSwap?> getLbtcLnV2SwapById(String swapId);
  Future<LbtcLnSwap?> getLbtcLnV2SwapByInvoice(String invoice);
  Future<List<BoltzSwapDbModel>> getSwaps(
      {BoltzVersion? version, SwapType? type});

  Future<BoltzSwapDbModel?> getSubmarineSwapDbModelByInvoice(String invoice);
  Future<BoltzSwapDbModel?> getSubmarineSwapDbModelByTxId(String txId);
  Future<BoltzSwapDbModel?> getReverseSwapDbModelByTxId(String txId);
  Future<BoltzSwapDbModel?> getSwapById(String swapId);
}

class BoltzSwapStorageNotifier extends AsyncNotifier<List<BoltzSwapDbModel>>
    implements BoltzSwapStorage {
  @override
  FutureOr<List<BoltzSwapDbModel>> build() async {
    final storage = await ref.watch(storageProvider.future);
    return storage.boltzSwapDbModels.all().sortByCreated();
  }

  Future<BoltzSwapDbModel?> _getSwapById(String boltzId) async {
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .where()
        .boltzIdEqualTo(boltzId)
        .findFirst();

    if (swap == null) {
      _logger.debug('Swap not found for id $boltzId');
    }

    return swap;
  }

  @override
  Future<void> save(BoltzSwapDbModel model) async {
    try {
      final storage = await ref.read(storageProvider.future);
      await storage.writeTxn(() async {
        final existing = await storage.boltzSwapDbModels
            .where()
            .boltzIdEqualTo(model.boltzId)
            .findFirst();
        if (existing != null) {
          final updated = model.copyWith(id: existing.id);
          await storage.boltzSwapDbModels.put(updated);
        } else {
          await storage.boltzSwapDbModels.put(model);
        }
      });

      final update = await storage.boltzSwapDbModels.all().sortByCreated();
      state = AsyncValue.data(update);
    } catch (e, st) {
      _logger.error('Error saving transaction', e, st);
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.boltzSwapDbModels.clear());

    final updated = await storage.boltzSwapDbModels.all().sortByCreated();
    state = AsyncValue.data(updated);
  }

  @override
  Future<void> delete(String orderId) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      storage.boltzSwapDbModels.where().boltzIdEqualTo(orderId).deleteAll();
    });
  }

  // Utility method to consolidate the saving of boltz V2 swap data
  @override
  Future<void> saveBoltzSwapResponse({
    required TransactionDbModel txnDbModel,
    required BoltzSwapDbModel swapDbModel,
    required KeyPair keys,
    required PreImage preimage,
  }) async {
    // Save keys to secure storage
    final keyPairStorageModel = KeyPairStorageModel.fromKeyPair(keys);
    await ref.read(secureStorageProvider).save(
          key: swapDbModel.privateKeyStorageKey,
          value: jsonEncode(keyPairStorageModel.toJson()),
        );

    // Save pre-image to secure storage
    final preImageStorageModel = PreImageStorageModel.fromPreImage(preimage);
    await ref.read(secureStorageProvider).save(
          key: swapDbModel.preImageStorageKey,
          value: jsonEncode(preImageStorageModel.toJson()),
        );

    // Save general transaction data
    await ref.read(transactionStorageProvider.notifier).save(txnDbModel);

    // Save boltz swap data
    await save(swapDbModel);
  }

  @override
  Future<LbtcLnSwap?> getLbtcLnV2SwapById(String swapId) async {
    final swap = await _getSwapById(swapId);

    if (swap == null) return null;

    final secureStorage = ref.read(secureStorageProvider);
    final (keysJson, _) = await secureStorage.get(swap.privateKeyStorageKey);
    final (preimageJson, _) = await secureStorage.get(swap.preImageStorageKey);

    if (keysJson == null) {
      throw Exception('Keys not found for swap $swapId');
    }

    if (preimageJson == null) {
      throw Exception('Pre-image not found for swap $swapId');
    }

    final keyPair = KeyPairStorageModel.fromJson(jsonDecode(keysJson));
    final preImage = PreImageStorageModel.fromJson(jsonDecode(preimageJson));
    return swap.toV2SwapResponse(keyPair, preImage);
  }

  @override
  Future<LbtcLnSwap?> getLbtcLnV2SwapByInvoice(String invoice) async {
    logger.debug('[BoltzStorage] Get swap for invoice $invoice');
    final secureStorage = ref.read(secureStorageProvider);
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .where()
        .invoiceEqualTo(invoice)
        .findFirst();

    if (swap == null) {
      _logger.debug('Swap not found for invoice $invoice');
      return null;
    }

    final (keysJson, _) = await secureStorage.get(swap.privateKeyStorageKey);
    final (preimageJson, _) = await secureStorage.get(swap.preImageStorageKey);

    if (keysJson == null) {
      throw Exception('Keys not found for swap ${swap.boltzId}');
    }

    if (preimageJson == null) {
      throw Exception('Pre-image not found for swap ${swap.boltzId}');
    }

    final keyPair = KeyPairStorageModel.fromJson(jsonDecode(keysJson));
    final preImage = PreImageStorageModel.fromJson(jsonDecode(preimageJson));
    return swap.toV2SwapResponse(keyPair, preImage);
  }

  @override
  Future<void> updateBoltzSwapStatus({
    required String boltzId,
    required BoltzSwapStatus status,
  }) async {
    final swap = await _getSwapById(boltzId);
    if (swap == null) return;

    final updated = swap.copyWith(lastKnownStatus: status);
    await save(updated);
  }

  @override
  Future<void> updateSubmarineOnBroadcast({
    required String boltzId,
    required String txId,
  }) async {
    final swap = await _getSwapById(boltzId);
    if (swap == null) return;

    // for submarine swaps, the outgoing send tx is what we want to cache for tx list
    await ref.read(transactionStorageProvider.notifier).updateTxHash(
          serviceOrderId: boltzId,
          newTxHash: txId,
        );

    final updated = swap.copyWith(
        onchainSubmarineTxId: txId,
        // - this isn't a boltz status, but our own added one. see comment on status for why this is necessary
        lastKnownStatus: BoltzSwapStatus.submarineBroadcasted);
    await save(updated);
  }

  @override
  Future<void> updateRefundTxId({
    required String boltzId,
    required String txId,
  }) async {
    final swap = await _getSwapById(boltzId);
    if (swap == null) return;

    //Note: for submarine swaps, we aren't marking the refund tx, can if needed can cache here
    final updated = swap
        .copyWith(refundTxId: txId)
        .copyWith(lastKnownStatus: BoltzSwapStatus.swapRefunded);
    await save(updated);
  }

  @override
  Future<List<BoltzSwapDbModel>> getSwaps(
      {BoltzVersion? version, SwapType? type}) async {
    final allSwaps = state.value ?? [];
    return allSwaps.where((swap) {
      bool matchesVersion = version == null || swap.version == version;
      bool matchesType = type == null || swap.kind == type;
      return matchesVersion && matchesType;
    }).toList();
  }

  @override
  Future<BoltzSwapDbModel?> getSubmarineSwapDbModelByTxId(String txId) async {
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .filter()
        .onchainSubmarineTxIdEqualTo(txId)
        .findFirst();

    return swap;
  }

  @override
  Future<BoltzSwapDbModel?> getReverseSwapDbModelByTxId(String txId) async {
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .filter()
        .claimTxIdEqualTo(txId)
        .findFirst();

    return swap;
  }

  @override
  Future<BoltzSwapDbModel?> getSubmarineSwapDbModelByInvoice(
      String invoice) async {
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .where()
        .invoiceEqualTo(invoice)
        .findFirst();

    return swap;
  }

  @override
  Future<void> updateReverseSwapClaim({
    required String boltzId,
    required String claimTxId,
    required String receiveAddress,
    required int outAmount,
    required int fee,
  }) async {
    logger.debug(
        '[Boltz] Updating reverse swap claim for $boltzId with: tx $claimTxId - receive $receiveAddress - amount $outAmount - fee $fee');

    // Update Boltz data model
    final swap = await _getSwapById(boltzId);
    if (swap != null) {
      logger.debug(
          '[Boltz] Found existing swap for $boltzId. Current claimTxId: ${swap.claimTxId}');

      final updated = swap
          .copyWith(claimTxId: claimTxId)
          .copyWith(lastKnownStatus: BoltzSwapStatus.invoiceSettled);

      try {
        await save(updated);
        logger.debug('[Boltz] Successfully saved updated swap for $boltzId');
      } catch (e) {
        logger.error('[Boltz] Error saving updated swap for $boltzId: $e');
      }
    } else {
      logger.error(
          '[Boltz] Error: Swap not found for $boltzId when trying to update claim');
    }

    // Update transaction data model
    try {
      await ref
          .read(transactionStorageProvider.notifier)
          .updateReverseSwapClaim(
            boltzId: boltzId,
            claimTxId: claimTxId,
            receiveAddress: receiveAddress,
            outAmount: outAmount,
            fee: fee,
          );
      logger
          .debug('[Boltz] Successfully updated transaction data for $boltzId');
    } catch (e) {
      logger.error('[Boltz] Error updating transaction data for $boltzId: $e');
    }
  }

  @override
  Future<BoltzSwapDbModel?> getSwapById(String swapId) async {
    final storage = await ref.read(storageProvider.future);
    return await storage.boltzSwapDbModels
        .where()
        .boltzIdEqualTo(swapId)
        .findFirst();
  }
}
