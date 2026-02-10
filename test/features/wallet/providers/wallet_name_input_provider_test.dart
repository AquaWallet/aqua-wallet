import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:aqua/features/wallet/models/wallet_state.dart';
import 'package:aqua/features/wallet/providers/stored_wallets_provider.dart';
import 'package:aqua/features/wallet/providers/wallet_name_input_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../mocks/stored_wallets_provider_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WalletNameInputProvider - Initial State', () {
    test('should initialize with empty string when wallet is null', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final text = await container.read(walletNameInputProvider(null).future);

      expect(text, '');
    });

    test('should initialize with wallet name when wallet is provided',
        () async {
      final wallet = StoredWallet(
        id: 'wallet-1',
        name: 'Test Wallet',
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final text = await container.read(walletNameInputProvider(wallet).future);

      expect(text, 'Test Wallet');
    });

    test('should initialize with empty string for wallet with empty name',
        () async {
      final wallet = StoredWallet(
        id: 'wallet-2',
        name: '',
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final text = await container.read(walletNameInputProvider(wallet).future);

      expect(text, '');
    });
  });

  group('WalletNameInputProvider - Update Text', () {
    test('should update text when updateText is called', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('New Name');

      final text = await container.read(walletNameInputProvider(null).future);

      expect(text, 'New Name');
    });

    test('should update text multiple times', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      final notifier = container.read(walletNameInputProvider(null).notifier);

      await notifier.updateText('First');
      var text = await container.read(walletNameInputProvider(null).future);
      expect(text, 'First');

      await notifier.updateText('Second');
      text = await container.read(walletNameInputProvider(null).future);
      expect(text, 'Second');

      await notifier.updateText('Third');
      text = await container.read(walletNameInputProvider(null).future);
      expect(text, 'Third');
    });

    test('should handle special characters in text', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('My-Wallet_2024!');

      final text = await container.read(walletNameInputProvider(null).future);

      expect(text, 'My-Wallet_2024!');
    });

    test('should handle unicode characters in text', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('🔒 Safe Wallet 💰');

      final text = await container.read(walletNameInputProvider(null).future);

      expect(text, '🔒 Safe Wallet 💰');
    });
  });

  group('WalletNameInputProvider - Validation', () {
    test('should throw error when text is empty after being touched', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('');

      final state = container.read(walletNameInputProvider(null));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.empty,
          ),
        ),
      );
    });

    test('should throw error when text is too long', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('123456789012345678901234');

      final state = container.read(walletNameInputProvider(null));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.tooLong,
          ),
        ),
      );
    });

    test('should throw error when name is duplicate', () async {
      final existingWallet = StoredWallet(
        id: 'wallet-1',
        name: 'My Wallet',
        createdAt: DateTime.now(),
      );

      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: WalletState(wallets: [existingWallet]),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);
      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('My Wallet');

      final state = container.read(walletNameInputProvider(null));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.duplicate,
          ),
        ),
      );
    });

    test('should be valid when editing same wallet with same name', () async {
      final existingWallet = StoredWallet(
        id: 'wallet-1',
        name: 'My Wallet',
        createdAt: DateTime.now(),
      );

      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: WalletState(wallets: [existingWallet]),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);
      await container.read(walletNameInputProvider(existingWallet).future);

      await container
          .read(walletNameInputProvider(existingWallet).notifier)
          .updateText('My Wallet');

      final text =
          await container.read(walletNameInputProvider(existingWallet).future);

      expect(text, 'My Wallet');
    });

    test('should be valid when name is at 23 character limit', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('12345678901234567890123');

      final text = await container.read(walletNameInputProvider(null).future);

      expect(text, '12345678901234567890123');
    });
  });

  group('WalletNameInputProvider - Edge Cases', () {
    test('should handle whitespace-only text', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('   ');

      final text = await container.read(walletNameInputProvider(null).future);

      expect(text, '   ');
    });

    test('should throw error for very long names', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('This is a very long wallet name that exceeds the limit');

      final state = container.read(walletNameInputProvider(null));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.tooLong,
          ),
        ),
      );
    });

    test('should be case-insensitive for duplicates', () async {
      final existingWallet = StoredWallet(
        id: 'wallet-1',
        name: 'My Wallet',
        createdAt: DateTime.now(),
      );

      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: WalletState(wallets: [existingWallet]),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);
      await container.read(walletNameInputProvider(null).future);

      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('my wallet');

      final state = container.read(walletNameInputProvider(null));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.duplicate,
          ),
        ),
      );
    });
  });

  group('WalletNameInputProvider - Touched State Validation', () {
    test(
        'should not validate when creating new wallet with initial empty state',
        () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      // Get initial state - should be empty and not show error
      final initialState =
          await container.read(walletNameInputProvider(null).future);

      expect(initialState, '');

      // State should be data, not error
      final state = container.read(walletNameInputProvider(null));
      expect(state, isA<AsyncData<String>>());
    });

    test('should validate empty text after user interaction', () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(walletNameInputProvider(null).future);

      // User types something
      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('Valid Name');

      // Then clears it
      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('');

      // Now it should show error because field was touched
      final state = container.read(walletNameInputProvider(null));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.empty,
          ),
        ),
      );
    });

    test('should validate immediately when editing existing wallet', () async {
      final existingWallet = StoredWallet(
        id: 'wallet-1',
        name: 'My Wallet',
        createdAt: DateTime.now(),
      );

      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: WalletState(wallets: [existingWallet]),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);
      await container.read(walletNameInputProvider(existingWallet).future);

      // User clears the existing wallet name
      await container
          .read(walletNameInputProvider(existingWallet).notifier)
          .updateText('');

      // Should show error immediately because it's an existing wallet
      final state = container.read(walletNameInputProvider(existingWallet));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.empty,
          ),
        ),
      );
    });

    test(
        'should validate immediately when editing existing wallet with duplicate name',
        () async {
      final existingWallet1 = StoredWallet(
        id: 'wallet-1',
        name: 'Wallet 1',
        createdAt: DateTime.now(),
      );

      final existingWallet2 = StoredWallet(
        id: 'wallet-2',
        name: 'Wallet 2',
        createdAt: DateTime.now(),
      );

      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: WalletState(wallets: [existingWallet1, existingWallet2]),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(storedWalletsProvider.future);
      await container.read(walletNameInputProvider(existingWallet1).future);

      // Try to rename to duplicate name
      await container
          .read(walletNameInputProvider(existingWallet1).notifier)
          .updateText('Wallet 2');

      // Should show error immediately
      final state = container.read(walletNameInputProvider(existingWallet1));

      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.duplicate,
          ),
        ),
      );
    });

    test('should only validate after first change when creating new wallet',
        () async {
      final mockWalletsNotifier = MockStoredWalletsNotifier(
        initialState: const WalletState(wallets: []),
      );

      final container = ProviderContainer(overrides: [
        storedWalletsProvider.overrideWith(() => mockWalletsNotifier),
      ]);
      addTearDown(container.dispose);

      // Initial state - no validation
      await container.read(walletNameInputProvider(null).future);
      var state = container.read(walletNameInputProvider(null));
      expect(state, isA<AsyncData<String>>());

      // First change - validation kicks in
      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('Valid Name');

      state = container.read(walletNameInputProvider(null));
      expect(state, isA<AsyncData<String>>());
      expect(state.valueOrNull, 'Valid Name');

      // Subsequent changes are validated
      await container
          .read(walletNameInputProvider(null).notifier)
          .updateText('123456789012345678901234'); // Too long

      state = container.read(walletNameInputProvider(null));
      expect(
        state,
        isA<AsyncError>().having(
          (s) => s.error,
          'error',
          isA<WalletNameValidationException>().having(
            (e) => e.type,
            'type',
            WalletNameValidationExceptionType.tooLong,
          ),
        ),
      );
    });
  });
}
