import 'dart:convert';

import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:aqua/features/wallet/providers/stored_wallets_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/storage_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to create a container with mocked secure storage
  ProviderContainer createContainer({
    required List<StoredWallet> wallets,
    String? currentWalletId,
  }) {
    final mockStorage = MockSecureStorageProvider();

    // Setup mock storage responses
    final walletsJson = jsonEncode(wallets.map((w) => w.toJson()).toList());
    when(() => mockStorage.get(kStoredWalletsListKey))
        .thenAnswer((_) async => (walletsJson, null));

    when(() => mockStorage.get(StorageKeys.currentWalletId))
        .thenAnswer((_) async => (currentWalletId, null));

    // Setup save method to capture and update the in-memory state
    String? savedWalletsJson = walletsJson;
    when(() => mockStorage.save(
        key: kStoredWalletsListKey,
        value: any(named: 'value'))).thenAnswer((invocation) async {
      savedWalletsJson = invocation.namedArguments[const Symbol('value')];
      // Update the mock to return the new value
      when(() => mockStorage.get(kStoredWalletsListKey))
          .thenAnswer((_) async => (savedWalletsJson, null));
      return null;
    });

    when(() => mockStorage.save(
        key: StorageKeys.currentWalletId,
        value: any(named: 'value'))).thenAnswer((_) async {
      return null;
    });

    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
    );

    return container;
  }

  group('StoredWalletsProvider - Reorder Wallets', () {
    test('should reorder wallet from top to bottom', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Move first wallet to last position (oldIndex: 0, newIndex: 2)
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 2);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify order changed
      expect(wallets.length, 3);
      expect(wallets[0].id, 'wallet-2');
      expect(wallets[1].id, 'wallet-3');
      expect(wallets[2].id, 'wallet-1');
    });

    test('should reorder wallet from bottom to top', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Move last wallet to first position (oldIndex: 2, newIndex: 0)
      await container.read(storedWalletsProvider.notifier).reorderWallets(2, 0);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify order changed
      expect(wallets.length, 3);
      expect(wallets[0].id, 'wallet-3');
      expect(wallets[1].id, 'wallet-1');
      expect(wallets[2].id, 'wallet-2');
    });

    test('should reorder wallet one position down', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Move first wallet one position down (oldIndex: 0, newIndex: 1)
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 1);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify order changed
      expect(wallets.length, 3);
      expect(wallets[0].id, 'wallet-2');
      expect(wallets[1].id, 'wallet-1');
      expect(wallets[2].id, 'wallet-3');
    });

    test('should reorder wallet one position up', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Move second wallet one position up (oldIndex: 1, newIndex: 0)
      await container.read(storedWalletsProvider.notifier).reorderWallets(1, 0);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify order changed
      expect(wallets.length, 3);
      expect(wallets[0].id, 'wallet-2');
      expect(wallets[1].id, 'wallet-1');
      expect(wallets[2].id, 'wallet-3');
    });

    test('should handle reordering middle wallet in larger list', () async {
      final wallets = List.generate(
        5,
        (index) => StoredWallet(
          id: 'wallet-$index',
          name: 'Wallet $index',
          createdAt: DateTime.now(),
        ),
      );

      final container = createContainer(
        wallets: wallets,
        currentWalletId: wallets[0].id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Move middle wallet (index 2) to index 4
      await container.read(storedWalletsProvider.notifier).reorderWallets(2, 4);

      final state = await container.read(storedWalletsProvider.future);
      final reorderedWallets = state.wallets;

      expect(reorderedWallets.length, 5);
      expect(reorderedWallets[0].id, 'wallet-0');
      expect(reorderedWallets[1].id, 'wallet-1');
      expect(reorderedWallets[2].id, 'wallet-3');
      expect(reorderedWallets[3].id, 'wallet-4');
      expect(reorderedWallets[4].id, 'wallet-2');
    });
  });

  group('StoredWalletsProvider - Reorder Safety', () {
    test('should not lose any wallets during reordering', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Reorder wallets
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 2);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify all wallets are still present
      expect(wallets.length, 3);
      expect(wallets.map((w) => w.id).toSet(), {
        'wallet-1',
        'wallet-2',
        'wallet-3',
      });
    });

    test('should preserve wallet data integrity during reordering', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        description: 'My first wallet',
        createdAt: DateTime(2024, 1, 1),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        description: 'My second wallet',
        createdAt: DateTime(2024, 2, 1),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Reorder wallets
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 1);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify wallet data is intact
      final movedWallet = wallets.firstWhere((w) => w.id == 'wallet-1');
      expect(movedWallet.name, 'First Wallet');
      expect(movedWallet.description, 'My first wallet');
      expect(movedWallet.createdAt, DateTime(2024, 1, 1));
    });

    test('should preserve current wallet selection after reordering', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet2.id, // Second wallet is selected
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Reorder wallets - move selected wallet
      await container.read(storedWalletsProvider.notifier).reorderWallets(1, 0);

      final state = await container.read(storedWalletsProvider.future);

      // Verify current wallet is still selected
      expect(state.currentWallet?.id, 'wallet-2');
    });

    test('should not create duplicate wallets during reordering', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Reorder wallets
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 2);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify no duplicates by checking unique IDs
      final uniqueIds = wallets.map((w) => w.id).toSet();
      expect(uniqueIds.length, wallets.length);
    });

    test('should handle reordering with single wallet gracefully', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'Only Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Try to reorder single wallet (should be no-op)
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 0);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify wallet is still there and unchanged
      expect(wallets.length, 1);
      expect(wallets[0].id, 'wallet-1');
    });

    test('should handle multiple sequential reorders correctly', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        createdAt: DateTime.now(),
      );
      final wallet4 = StoredWallet(
        id: 'wallet-4',
        name: 'Fourth Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3, wallet4],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Perform multiple reorders
      await container
          .read(storedWalletsProvider.notifier)
          .reorderWallets(0, 3); // Move first to last

      await container
          .read(storedWalletsProvider.notifier)
          .reorderWallets(3, 1); // Move it back to middle

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify all wallets still present
      expect(wallets.length, 4);
      expect(wallets.map((w) => w.id).toSet(), {
        'wallet-1',
        'wallet-2',
        'wallet-3',
        'wallet-4',
      });
    });

    test('should preserve wallet metadata during reordering', () async {
      final now = DateTime.now();
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        description: 'Description 1',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        description: 'Description 2',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final wallet3 = StoredWallet(
        id: 'wallet-3',
        name: 'Third Wallet',
        description: 'Description 3',
        createdAt: now,
      );

      final container = createContainer(
        wallets: [wallet1, wallet2, wallet3],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Reorder wallets
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 2);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify all metadata is preserved
      for (final wallet in wallets) {
        if (wallet.id == 'wallet-1') {
          expect(wallet.name, 'First Wallet');
          expect(wallet.description, 'Description 1');
          expect(wallet.createdAt, now.subtract(const Duration(days: 2)));
        } else if (wallet.id == 'wallet-2') {
          expect(wallet.name, 'Second Wallet');
          expect(wallet.description, 'Description 2');
          expect(wallet.createdAt, now.subtract(const Duration(days: 1)));
        } else if (wallet.id == 'wallet-3') {
          expect(wallet.name, 'Third Wallet');
          expect(wallet.description, 'Description 3');
          expect(wallet.createdAt, now);
        }
      }
    });
  });

  group('StoredWalletsProvider - Reorder Edge Cases', () {
    test('should handle reorder to same position (no-op)', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Reorder to same position
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 0);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify order unchanged
      expect(wallets[0].id, 'wallet-1');
      expect(wallets[1].id, 'wallet-2');
    });

    test('should handle reordering with two wallets', () async {
      final wallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'First Wallet',
        createdAt: DateTime.now(),
      );
      final wallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Second Wallet',
        createdAt: DateTime.now(),
      );

      final container = createContainer(
        wallets: [wallet1, wallet2],
        currentWalletId: wallet1.id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Swap the two wallets
      await container.read(storedWalletsProvider.notifier).reorderWallets(0, 1);

      final state = await container.read(storedWalletsProvider.future);
      final wallets = state.wallets;

      // Verify they swapped
      expect(wallets.length, 2);
      expect(wallets[0].id, 'wallet-2');
      expect(wallets[1].id, 'wallet-1');
    });

    test('should handle reordering in large list', () async {
      // Create 20 wallets
      final wallets = List.generate(
        20,
        (index) => StoredWallet(
          id: 'wallet-$index',
          name: 'Wallet $index',
          createdAt: DateTime.now(),
        ),
      );

      final container = createContainer(
        wallets: wallets,
        currentWalletId: wallets[0].id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      // Move wallet from position 5 to position 15
      await container
          .read(storedWalletsProvider.notifier)
          .reorderWallets(5, 15);

      final state = await container.read(storedWalletsProvider.future);
      final reorderedWallets = state.wallets;

      // Verify all wallets still present
      expect(reorderedWallets.length, 20);
      expect(
        reorderedWallets.map((w) => w.id).toSet().length,
        20,
      );

      // Verify wallet-5 is now at position 15
      expect(reorderedWallets[15].id, 'wallet-5');
    });
  });

  group('StoredWalletsProvider - Wallet Limit', () {
    test('kMaxWallets should be 21', () {
      expect(kMaxWallets, 21);
    });

    test('isWalletLimitReached returns false when under limit', () async {
      final wallets = List.generate(
        5,
        (index) => StoredWallet(
          id: 'wallet-$index',
          name: 'Wallet $index',
          createdAt: DateTime.now(),
        ),
      );

      final container = createContainer(
        wallets: wallets,
        currentWalletId: wallets[0].id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      final isLimitReached =
          container.read(storedWalletsProvider.notifier).isWalletLimitReached;

      expect(isLimitReached, false);
    });

    test('isWalletLimitReached returns true when over limit', () async {
      final wallets = List.generate(
        kMaxWallets + 5,
        (index) => StoredWallet(
          id: 'wallet-$index',
          name: 'Wallet $index',
          createdAt: DateTime.now(),
        ),
      );

      final container = createContainer(
        wallets: wallets,
        currentWalletId: wallets[0].id,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      final isLimitReached =
          container.read(storedWalletsProvider.notifier).isWalletLimitReached;

      expect(isLimitReached, true);
    });

    test('isWalletLimitReached returns false when no wallets', () async {
      final container = createContainer(
        wallets: [],
        currentWalletId: null,
      );
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);

      final isLimitReached =
          container.read(storedWalletsProvider.notifier).isWalletLimitReached;

      expect(isLimitReached, false);
    });
  });
}
