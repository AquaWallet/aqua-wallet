import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/boltz/storage/boltz_storage_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/providers/sideshift_storage_provider.dart';
import 'package:aqua/features/sideswap/providers/peg_storage_provider.dart';
import 'package:aqua/features/swaps/providers/swap_storage_provider.dart';
import 'package:aqua/features/transactions/providers/transactions_storage_provider.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:restart_app/restart_app.dart';

// Storage key for the list of wallets
const kStoredWalletsListKey = 'stored_wallets_list';
// Prefix for individual wallet mnemonic keys
const kStoredWalletMnemonicPrefix = 'wallet_mnemonic_';

const _kMaxWalletNameLength = 23;

final _logger = CustomLogger(FeatureFlag.multiWallet);

String _uniqueWalletName(String name, List<StoredWallet> existingWallets) {
  final existingLower =
      existingWallets.map((w) => w.name.toLowerCase()).toSet();
  String candidate = name.trim();
  if (candidate.isEmpty) candidate = 'Wallet';
  if (!existingLower.contains(candidate.toLowerCase())) {
    return candidate.length > _kMaxWalletNameLength
        ? candidate.substring(0, _kMaxWalletNameLength)
        : candidate;
  }
  for (var n = 2; n <= kMaxWallets; n++) {
    final suffix = ' ($n)';
    final next = candidate.length + suffix.length <= _kMaxWalletNameLength
        ? '$candidate$suffix'
        : '${candidate.substring(0, _kMaxWalletNameLength - suffix.length)}$suffix';
    if (!existingLower.contains(next.toLowerCase())) return next;
  }
  return '$candidate (${existingWallets.length + 1})';
}

// Provider for accessing and managing stored wallets
final storedWalletsProvider =
    AsyncNotifierProvider<StoredWalletsNotifier, WalletState>(
        StoredWalletsNotifier.new);

class StoredWalletsNotifier extends AsyncNotifier<WalletState> {
  /// Returns true if the maximum number of wallets has been reached
  bool get isWalletLimitReached {
    final wallets = state.valueOrNull?.wallets ?? [];
    return wallets.length >= kMaxWallets;
  }

  @override
  FutureOr<WalletState> build() async {
    return _loadWalletState();
  }

  // Load the wallet state from secure storage
  Future<WalletState> _loadWalletState() async {
    try {
      final wallets = await loadStoredWallets();
      final (currentWalletId, _) = await ref
          .read(secureStorageProvider)
          .get(StorageKeys.currentWalletId);

      if (currentWalletId != null) {
        final currentWallet =
            wallets.firstWhereOrNull((w) => w.id == currentWalletId);

        if (currentWallet != null) {
          return WalletState(
            wallets: wallets,
            currentWallet: currentWallet,
          );
        }
      }

      return WalletState(
        wallets: wallets,
        currentWallet: wallets.firstOrNull,
      );
    } catch (e) {
      _logger.error('Error loading wallet state: $e');
      return WalletState.initial();
    }
  }

  // Load the list of stored wallets from secure storage
  Future<List<StoredWallet>> loadStoredWallets() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final result = await storage.get(kStoredWalletsListKey);
      final storedWalletsJson = result.$1;

      _logger.debug(
          'Loading stored wallets: ${storedWalletsJson != null ? 'found data' : 'no data'}');

      if (storedWalletsJson == null) {
        return [];
      }

      try {
        final List<dynamic> walletsData = jsonDecode(storedWalletsJson);
        final wallets = walletsData
            .map((data) => StoredWallet.fromJson(data as Map<String, dynamic>))
            .toList();

        _logger.debug('Loaded ${wallets.length} wallets');
        return wallets;
      } catch (e) {
        _logger.error('Error parsing stored wallets: $e');
        return [];
      }
    } catch (e) {
      _logger.error('Error loading stored wallets: $e');
      return [];
    }
  }

  // Add a new wallet to the list
  Future<void> addWallet({
    String? mnemonic,
    required String name,
    String? description,
    SamRockAppLink? samRockAppLink,
    WalletOperationType? operationType,
  }) async {
    state = const AsyncValue.loading();

    try {
      final storage = ref.read(secureStorageProvider);
      // Generate BIP32 fingerprint from mnemonic using the utility function
      final effectiveMnemonic = mnemonic ?? await _generateNewMnemonic();
      final walletId = generateBip32Fingerprint(effectiveMnemonic);
      _logger.debug('Generated wallet fingerprint: $walletId');

      // Save the mnemonic with the wallet ID
      await storage.save(
          key: StorageKeys.mnemonic(walletId), value: effectiveMnemonic);

      // Create a new wallet entry
      final newWallet = StoredWallet(
        id: walletId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        samRockAppLink: samRockAppLink,
      );

      // Get current state
      final currentState = await _loadWalletState();
      final currentWallets = currentState.wallets;

      // Check if wallet with this ID already exists
      final existingWallet =
          currentWallets.where((w) => w.id == walletId).toList();
      if (existingWallet.isNotEmpty) {
        _logger.info(
            'Wallet with this mnemonic already exists, skipping addition');

        await storage.save(key: StorageKeys.currentWalletId, value: walletId);
        state = AsyncValue.data(WalletState(
          wallets: currentState.wallets,
          currentWallet: existingWallet.first.copyWith(
            samRockAppLink:
                samRockAppLink ?? existingWallet.first.samRockAppLink,
          ),
        ));
        await switchToWallet(walletId);
        return;
      }

      final uniqueName = _uniqueWalletName(name, currentWallets);
      final newWalletWithName = newWallet.copyWith(name: uniqueName);
      final updatedWallets = [...currentWallets, newWalletWithName];
      _logger
          .debug('Adding new wallet. Total wallets: ${updatedWallets.length}');

      // Convert to JSON and save
      final walletsJson =
          jsonEncode(updatedWallets.map((w) => w.toJson()).toList());

      // Save the updated list
      await storage.save(key: kStoredWalletsListKey, value: walletsJson);

      state = AsyncValue.data(WalletState(
        wallets: updatedWallets,
        currentWallet: newWalletWithName,
        lastOperationType: operationType,
      ));

      // Switch to the new wallet without triggering the switching animation
      // since we're already in a wallet creation flow
      await _performWalletSwitch(walletId);

      _logger
          .info('Wallet "$uniqueName" added successfully with ID: $walletId');
    } catch (e, stack) {
      _logger.error('Error adding wallet: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<String> _generateNewMnemonic() async {
    final mnemonicList = await ref.read(liquidProvider).generateMnemonic12();
    if (mnemonicList == null) {
      throw Exception("Failed to generate new mnemonic");
    }
    return mnemonicList.join(' ');
  }

  /// Clears all database records associated with a wallet (transactions, swaps, etc.)
  Future<void> _clearWalletDatabaseRecords(String walletId) async {
    await ref
        .read(transactionStorageProvider.notifier)
        .clearByWalletId(walletId);
    await ref.read(swapStorageProvider.notifier).clearByWalletId(walletId);
    await ref.read(boltzStorageProvider.notifier).clearByWalletId(walletId);
    await ref.read(pegStorageProvider.notifier).clearByWalletId(walletId);
  }

  // Delete a wallet from the list
  Future<void> deleteWallet(String walletId) async {
    state = const AsyncValue.loading();

    try {
      final storage = ref.read(secureStorageProvider);

      // Get current state before deletion
      final currentState = await _loadWalletState();
      final currentWallets = currentState.wallets;

      // Find the wallet to delete
      final wallet = currentWallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => throw Exception('Wallet not found'),
      );

      _logger.info('Starting deletion of wallet "${wallet.name}"...');

      // Delete the Jan3 token for this wallet if one exists
      if (wallet.profileResponse != null) {
        try {
          final storage = ref.read(secureStorageProvider);
          await storage
              .delete(Jan3AuthTokenManager.tokenKeyForWallet(walletId));
        } catch (e) {
          _logger.warning('Error deleting Jan3 token for wallet: $e');
        }
      }

      final (walletMnemonic, _) =
          await storage.get(StorageKeys.mnemonic(walletId));
      final (legacyMnemonic, _) = await storage.get(StorageKeys.legacyMnemonic);
      if (walletMnemonic != null && walletMnemonic == legacyMnemonic) {
        // delete legacy mnemonic key
        // so the next time app opens, it will exit migration
        await storage.delete(StorageKeys.legacyMnemonic);
      }

      // Delete the mnemonic for this wallet using consistent key format
      await storage.delete(StorageKeys.mnemonic(walletId));

      // Remove from the list of wallets
      final updatedWallets =
          currentWallets.where((w) => w.id != walletId).toList();

      // Save the updated list
      await storage.save(
        key: kStoredWalletsListKey,
        value: jsonEncode(updatedWallets.map((w) => w.toJson()).toList()),
      );

      // Double-check by re-reading the actual stored wallets
      final actualStoredWallets = await loadStoredWallets();

      if (actualStoredWallets.isEmpty) {
        await ref.read(sharedPreferencesProvider).clear();
        await ref.read(transactionStorageProvider.notifier).clear();
        await ref.read(swapStorageProvider.notifier).clear();
        await ref.read(boltzStorageProvider.notifier).clear();
        await ref.read(pegStorageProvider.notifier).clear();
        await ref.read(sideshiftStorageProvider.notifier).clear();

        // Clear the current wallet ID from storage
        await storage.delete(StorageKeys.currentWalletId);

        // Update state to show no wallets
        state = const AsyncValue.data(WalletState(
          wallets: [],
          currentWallet: null,
        ));

        if (Platform.isAndroid) {
          Restart.restartApp();
          return;
        }

        // Set operation state to idle after completing deletion
        ref.read(walletOperationProvider.notifier).state =
            WalletOperationState.idle;
        return;
      }

      // Clear all database records associated with the wallet
      await _clearWalletDatabaseRecords(walletId);

      final firstWalletId = actualStoredWallets.first.id;
      _logger.info('Wallet deleted. Switching to first wallet: $firstWalletId');
      await _performWalletSwitch(firstWalletId);
      ref.read(walletOperationProvider.notifier).state =
          WalletOperationState.idle;
    } catch (e, stack) {
      // Set operation state to idle on error
      ref.read(walletOperationProvider.notifier).state =
          WalletOperationState.idle;
      _logger.error('Error deleting wallet: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // Core wallet switching logic without operation state management
  Future<void> _performWalletSwitch(String walletId) async {
    _logger.info('Starting wallet switch to: $walletId');

    try {
      // 1. Perform full cleanup first to ensure clean state
      await ref.read(aquaConnectionProvider.notifier).fullCleanup();

      // 2. Get wallet data
      final storage = ref.read(secureStorageProvider);
      final (mnemonic, _) = await storage.get(StorageKeys.mnemonic(walletId));

      if (mnemonic == null) {
        throw Exception('Mnemonic not found for wallet ID: $walletId');
      }

      // 3. Find the wallet in the list
      final wallets = await loadStoredWallets();
      final wallet = wallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => throw Exception('Wallet with ID $walletId not found'),
      );

      // 4. Update current wallet ID in storage
      await storage.save(key: StorageKeys.currentWalletId, value: walletId);

      // 5. Connect to network with new wallet
      await ref.read(aquaConnectionProvider.notifier).connect();

      // 6. Update state with the new current wallet
      state = AsyncValue.data(WalletState(
        wallets: wallets,
        currentWallet: wallet,
      ));

      // 7. Force reload assets (and balances) after connection
      await ref.read(assetsProvider.notifier).reloadAssets();

      // 8. Invalidate transaction storage to reload transactions for new wallet
      ref.invalidate(transactionStorageProvider);

      // 9. Invalidate Jan3 auth provider to force fresh token check and profile
      // fetch for the new wallet (handles cached state from previous visits)
      ref.invalidate(jan3AuthProvider(walletId));

      _logger.info('Wallet switch completed successfully');
    } catch (e, stack) {
      _logger.error('Error during wallet switch: $e\n$stack');
      rethrow;
    }
  }

  // Switch to a wallet and connect to the network with animation
  Future<void> switchToWallet(String walletId) async {
    // Set switching state at the beginning
    ref.read(walletOperationProvider.notifier).state =
        WalletOperationState.switching;

    try {
      await _performWalletSwitch(walletId);

      // Set operation state to idle on success
      ref.read(walletOperationProvider.notifier).state =
          WalletOperationState.idle;
    } catch (e, stack) {
      // Set operation state to idle on error

      ref.read(walletOperationProvider.notifier).state =
          WalletOperationState.idle;

      _logger.error('Error switching wallet: $e\n$stack');
      rethrow;
    }
  }

  /// Saves a list of wallets to secure storage and updates provider state
  Future<void> saveWalletsList(List<StoredWallet> wallets) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final walletsJson = jsonEncode(wallets.map((w) => w.toJson()).toList());
      await storage.save(key: kStoredWalletsListKey, value: walletsJson);
      _logger.debug('Saved ${wallets.length} wallets to secure storage');

      // Update provider state after saving to storage
      final currentWalletId = await getCurrentWalletId();
      StoredWallet? currentWallet;

      if (currentWalletId != null) {
        try {
          currentWallet = wallets.firstWhere((w) => w.id == currentWalletId);
        } catch (e) {
          _logger.warning(
              'Current wallet ID $currentWalletId not found in saved wallets');
        }
      }

      state = AsyncValue.data(WalletState(
        wallets: wallets,
        currentWallet: currentWallet,
      ));

      _logger.debug('Updated provider state with ${wallets.length} wallets');
    } catch (e, stack) {
      _logger.error('Error saving wallets list: $e\n$stack');
      rethrow;
    }
  }

  /// Updates the name of a wallet
  Future<void> updateWalletName(String walletId, String newName) async {
    try {
      state = const AsyncValue.loading();

      // Get current wallets
      final wallets = await loadStoredWallets();

      // Find the wallet to update
      final walletIndex = wallets.indexWhere((w) => w.id == walletId);
      if (walletIndex == -1) {
        throw Exception('Wallet not found');
      }

      // Create updated wallet with new name
      final updatedWallet = wallets[walletIndex].copyWith(name: newName);

      // Replace in list
      final updatedWallets = List<StoredWallet>.from(wallets);
      updatedWallets[walletIndex] = updatedWallet;

      // Save updated list
      await saveWalletsList(updatedWallets);

      _logger.info('Successfully updated wallet name: $walletId -> $newName');
    } catch (e, stack) {
      _logger.error('Error updating wallet name: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> reorderWallets(int oldIndex, int newIndex) async {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      return;
    }

    final wallets = List<StoredWallet>.from(currentState.wallets);

    final wallet = wallets.removeAt(oldIndex);
    wallets.insert(newIndex, wallet);

    await saveWalletsList(wallets);

    _logger.debug('Successfully reordered wallets from $oldIndex to $newIndex');
  }

  /// Gets the current wallet ID from secure storage
  Future<String?> getCurrentWalletId() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final result = await storage.get(StorageKeys.currentWalletId);
      return result.$1;
    } catch (e) {
      _logger.error('Error getting current wallet ID: $e');
      return null;
    }
  }

  /// Updates a wallet with a Jan3 profile
  Future<void> updateWalletWithProfile(String walletId,
      ProfileResponse? profile, AuthTokenResponse? authToken) async {
    try {
      state = const AsyncValue.loading();

      // Get current wallets
      final wallets = await loadStoredWallets();

      // Find the wallet to update
      final walletIndex = wallets.indexWhere((w) => w.id == walletId);
      if (walletIndex == -1) {
        throw Exception('Wallet not found');
      }

      // Create updated wallet with profile
      final updatedWallet = wallets[walletIndex].copyWith(
        profileResponse: profile,
        authToken: authToken,
      );

      // Replace in list
      final updatedWallets = List<StoredWallet>.from(wallets);
      updatedWallets[walletIndex] = updatedWallet;

      // Save updated list
      await saveWalletsList(updatedWallets);

      _logger.info('Successfully updated wallet profile: $walletId');
    } catch (e, stack) {
      _logger.error('Error updating wallet profile: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

extension WalletStateExt on WalletState {
  StoredWallet? getWalletById(String walletId) {
    return wallets.firstWhereOrNull((w) => w.id == walletId);
  }
}
