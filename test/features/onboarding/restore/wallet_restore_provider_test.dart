import 'package:aqua/data/data.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/aqua_provider_mocks.dart';
import '../../../mocks/backup_reminder_provider_mocks.dart';
import '../../../mocks/liquid_provider_mocks.dart';
import '../../../mocks/stored_wallets_provider_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(<StoredWallet>[]);
  });

  group('WalletRestoreNotifier', () {
    late MockLiquidProvider mockLiquidProvider;
    late MockAquaConnectionProvider mockAquaConnectionProvider;
    late MockBackupReminderNotifier mockBackupReminderNotifier;
    late SharedPreferences mockSharedPreferences;

    const testMnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    final testWalletId = generateBip32Fingerprint(testMnemonic);
    final existingWallet = StoredWallet(
      id: testWalletId,
      name: 'Test Wallet',
      createdAt: DateTime.now(),
    );

    setUp(() async {
      mockLiquidProvider = MockLiquidProvider();
      mockAquaConnectionProvider = MockAquaConnectionProvider();
      mockBackupReminderNotifier = MockBackupReminderNotifier();
      mockSharedPreferences = await SharedPreferences.getInstance();

      when(() => mockLiquidProvider.validateMnemonic(any()))
          .thenAnswer((_) async => true);
    });

    test('throws WalletRestoreWalletAlreadyExistsException when wallet exists',
        () async {
      final walletState = WalletState(
        wallets: [existingWallet],
        currentWallet: existingWallet,
      );

      final mockStoredWalletsNotifierWithState =
          MockStoredWalletsNotifier(initialState: walletState);

      final containerWithState = ProviderContainer(
        overrides: [
          liquidProvider.overrideWithValue(mockLiquidProvider),
          storedWalletsProvider
              .overrideWith(() => mockStoredWalletsNotifierWithState),
          aquaConnectionProvider.overrideWith(() => mockAquaConnectionProvider),
          backupReminderProvider
              .overrideWith((ref) => mockBackupReminderNotifier),
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
      );

      await containerWithState.read(storedWalletsProvider.future);

      final notifier = containerWithState.read(walletRestoreProvider.notifier);

      await notifier.restore(testMnemonic, walletName: 'New Wallet Name');

      final state = containerWithState.read(walletRestoreProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error,
        isA<WalletRestoreWalletAlreadyExistsException>(),
      );

      containerWithState.dispose();
    });

    test('does not throw exception when wallet does not exist', () async {
      final mockStoredWalletsNotifierEmpty = MockStoredWalletsNotifier(
          initialState: const WalletState(wallets: []));

      final containerEmpty = ProviderContainer(
        overrides: [
          liquidProvider.overrideWithValue(mockLiquidProvider),
          storedWalletsProvider
              .overrideWith(() => mockStoredWalletsNotifierEmpty),
          aquaConnectionProvider.overrideWith(() => mockAquaConnectionProvider),
          backupReminderProvider
              .overrideWith((ref) => mockBackupReminderNotifier),
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
      );

      await containerEmpty.read(storedWalletsProvider.future);

      final notifier = containerEmpty.read(walletRestoreProvider.notifier);

      await notifier.restore(testMnemonic, walletName: 'New Wallet');

      final state = containerEmpty.read(walletRestoreProvider);
      expect(state.hasError, isFalse);

      containerEmpty.dispose();
    });
  });
}
