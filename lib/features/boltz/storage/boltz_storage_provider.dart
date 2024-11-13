import 'dart:async';
import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> updateSubmarineOnchainTxId({
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
    // NOTE: This is a one-time migration
    logger.d('[BoltzStorage] Preparing for migration to Isar');
    _migrateNormalSwapsToIsar();
    _migrateReverseSwapsToIsar();

    final storage = await ref.watch(storageProvider.future);
    return storage.boltzSwapDbModels.all().sortByCreated();
  }

  Future<void> _migrateNormalSwapsToIsar() async {
    try {
      final storage = await ref.read(storageProvider.future);
      final prefs = await SharedPreferences.getInstance();
      final toMigrate = prefs
          .getKeys()
          .where((k) => k.startsWith(BoltzStorageKeys.normalSwapPrefsPrefix));
      final network = await ref.read(liquidProvider).getNetwork();
      final electrumUrl = network!.electrumUrl!;
      final boltzUrl = ref.read(boltzEnvConfigProvider).apiUrl;

      if (toMigrate.isNotEmpty) {
        final count = toMigrate.length;
        logger.d('[BoltzStorage] Migrating $count normal swaps to Isar');
      }

      for (String key in toMigrate) {
        String? json = prefs.getString(key);
        if (json != null) {
          final id = key.split('_').last;
          final existingSwap = await storage.boltzSwapDbModels
              .where()
              .boltzIdEqualTo(id)
              .findFirst();
          if (existingSwap != null) {
            logger.d('[BoltzStorage] Swap already migrated: $id');
            continue;
          }

          final swap = BoltzSwapData.fromJson(jsonDecode(json));
          final storageKey = BoltzStorageKeys.getNormalSwapSecureStorageKey(id);
          final secureDataMap = await ref
              .read(boltzDataProvider)
              .fetchAndDecodeSecureData(storageKey);

          if (secureDataMap == null) {
            logger
                .d('[BoltzStorage] No secure data, skipping normal swap: $id');
            continue;
          }

          logger.d("[BoltzStorage] Migrating normal swap to db: $swap");

          // Save general transaction data
          final swapDbModel = BoltzSwapDbModel.fromLegacySwap(
            data: swap,
            electrumUrl: electrumUrl,
            boltzUrl: boltzUrl,
          );
          final transactionDbModel = TransactionDbModel.fromBoltzSwap(
            txhash: swap.onchainTxHash ?? '',
            assetId: ref.read(liquidProvider).lbtcId,
            swap: swap,
          );

          await _saveLegacyBoltzSwapResponse(
            txnDbModel: transactionDbModel,
            swapDbModel: swapDbModel,
            redeemScript: swap.response.redeemScript,
            secureData: swap.secureData,
          );

          logger.d("[BoltzStorage] Migrated normal swap to db: $id");

          // TODO: Enable once db caching has gone live, we want to keep a backup
          // prefs.remove(key);
          // await ref.read(secureStorageProvider).delete(secureStorageKey);

          final items = await storage.boltzSwapDbModels.all().sortByCreated();
          state = AsyncValue.data(items);
        }
      }
    } catch (e) {
      logger.e("[BoltzStorage] Submarine swap migration error: $e");
    }
  }

  Future<void> _migrateReverseSwapsToIsar() async {
    final storage = await ref.watch(storageProvider.future);
    final prefs = await SharedPreferences.getInstance();
    final toMigrate = prefs
        .getKeys()
        .where((k) => k.startsWith(BoltzStorageKeys.reverseSwapPrefsPrefix));
    final network = await ref.read(liquidProvider).getNetwork();
    final electrumUrl = network!.electrumUrl!;
    final boltzUrl = ref.read(boltzEnvConfigProvider).apiUrl;

    if (toMigrate.isNotEmpty) {
      final count = toMigrate.length;
      logger.d('[BoltzStorage] Migrating $count reverse swaps to Isar');
    }

    for (String key in toMigrate) {
      try {
        String? json = prefs.getString(key);
        if (json != null) {
          final id = key.split('_').last;
          final existingSwap = await storage.boltzSwapDbModels
              .where()
              .boltzIdEqualTo(id)
              .findFirst();
          if (existingSwap != null) {
            logger.d('[BoltzStorage] Swap already migrated: $id');
            continue;
          }

          final swap = BoltzReverseSwapData.fromJson(jsonDecode(json));
          final storageKey =
              BoltzStorageKeys.getReverseSwapSecureStorageKey(id);
          final secureDataMap = await ref
              .read(boltzDataProvider)
              .fetchAndDecodeSecureData(storageKey);

          if (secureDataMap == null) {
            logger
                .d('[BoltzStorage] No secure data, skipping reverse swap: $id');
            continue;
          }

          logger.d("[BoltzStorage] Migrating reverse swap to db: $swap");

          // Save general transaction data
          final swapDbModel = BoltzSwapDbModel.fromLegacyRevSwap(
            data: swap,
            electrumUrl: electrumUrl,
            boltzUrl: boltzUrl,
          );
          final transactionDbModel = TransactionDbModel.fromBoltzRevSwap(
            txhash: swap.onchainTxHash ?? '',
            assetId: ref.read(liquidProvider).lbtcId,
            swap: swap,
          );

          await _saveLegacyBoltzSwapResponse(
            txnDbModel: transactionDbModel,
            swapDbModel: swapDbModel,
            redeemScript: swap.response.redeemScript,
            secureData: swap.secureData,
          );

          logger.d("[BoltzStorage] Migrated reverse swap to db: $id");

          // TODO: Enable once db caching has gone live, we want to keep a backup
          // prefs.remove(key);
          // await ref.read(secureStorageProvider).delete(secureStorageKey);

          final items = await storage.boltzSwapDbModels.all().sortByCreated();
          state = AsyncValue.data(items);
        }
      } catch (e) {
        logger.e("[BoltzStorage] Reverse swap migration error: $e");
      }
    }
  }

  Future<BoltzSwapDbModel?> _getSwapById(String boltzId) async {
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .where()
        .boltzIdEqualTo(boltzId)
        .findFirst();

    if (swap == null) {
      logger.d('[BoltzStorage] Swap not found for id $boltzId');
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
      logger.e('[BoltzStorage] Error saving transaction', e, st);
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

  // Utility method to consolidate the saving of legacy boltz swap data
  Future<void> _saveLegacyBoltzSwapResponse({
    required TransactionDbModel txnDbModel,
    required BoltzSwapDbModel swapDbModel,
    required String redeemScript,
    required BoltzSwapSecureData secureData,
  }) async {
    // Save keys to secure storage
    final keyPairStorageModel = KeyPairStorageModel(
      publicKey: '', // don't need to store public key
      secretKey: secureData.privateKeyHex,
    );
    await ref.read(secureStorageProvider).save(
          key: swapDbModel.privateKeyStorageKey,
          value: jsonEncode(keyPairStorageModel.toJson()),
        );

    // Save pre-image to secure storage
    final preImageStorageModel = PreImageStorageModel(
      value: secureData.preimageHex ?? '',
      sha256: '',
      hash160: '',
    );
    await ref.read(secureStorageProvider).save(
          key: swapDbModel.preImageStorageKey,
          value: jsonEncode(preImageStorageModel.toJson()),
        );

    // Save general transaction data
    if (txnDbModel.txhash.isNotEmpty) {
      await ref.read(transactionStorageProvider.notifier).save(txnDbModel);
    }

    // Save boltz swap data
    await save(swapDbModel);

    // start
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
    logger.d('[BoltzStorage] Swap for invoice $invoice');
    final secureStorage = ref.read(secureStorageProvider);
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .where()
        .invoiceEqualTo(invoice)
        .findFirst();

    if (swap == null) {
      logger.d('[BoltzStorage] Swap not found for invoice $invoice');
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
  Future<void> updateSubmarineOnchainTxId({
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

    final updated = swap.copyWith(onchainSubmarineTxId: txId);
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

    if (swap == null) {
      final legacySwap = await ref
          .read(boltzDataProvider)
          .getBoltzNormalSwapDataByOnchainTx(txId);
      if (legacySwap == null) return null;

      return BoltzSwapDbModel.fromLegacySwap(data: legacySwap);
    }

    return swap;
  }

  @override
  Future<BoltzSwapDbModel?> getReverseSwapDbModelByTxId(String txId) async {
    final storage = await ref.read(storageProvider.future);
    final swap = await storage.boltzSwapDbModels
        .filter()
        .claimTxIdEqualTo(txId)
        .findFirst();

    if (swap == null) {
      final legacySwap = await ref
          .read(boltzDataProvider)
          .getBoltzReverseSwapDataByOnchainTx(txId);
      if (legacySwap == null) return null;

      return BoltzSwapDbModel.fromLegacyRevSwap(data: legacySwap);
    }

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
    logger.d(
        '[Boltz] Updating reverse swap claim for $boltzId with: tx $claimTxId - receive $receiveAddress - amount $outAmount - fee $fee');

    // Update Boltz data model
    final swap = await _getSwapById(boltzId);
    if (swap != null) {
      logger.d(
          '[Boltz] Found existing swap for $boltzId. Current claimTxId: ${swap.claimTxId}');

      final updated = swap
          .copyWith(claimTxId: claimTxId)
          .copyWith(lastKnownStatus: BoltzSwapStatus.invoiceSettled);

      try {
        await save(updated);
        logger.d('[Boltz] Successfully saved updated swap for $boltzId');
      } catch (e) {
        logger.e('[Boltz] Error saving updated swap for $boltzId: $e');
      }
    } else {
      logger.e(
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
      logger.d('[Boltz] Successfully updated transaction data for $boltzId');
    } catch (e) {
      logger.e('[Boltz] Error updating transaction data for $boltzId: $e');
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
