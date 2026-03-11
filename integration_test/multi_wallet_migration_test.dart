import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/secure_storate_mocks.dart';

void main() {
  final mockStorage = MockSecureStorage();
  const testMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  testWidgets('Test legacy mnemonic migration', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    // Set up mock secure storage with a legacy mnemonic
    mockStorage.setMockData(
      StorageKeys.legacyMnemonic,
      (testMnemonic, null),
    );

    // Load app widget with mocked storage
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
      child: const AquaApp(),
    ));

    // Trigger frames to allow migration to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // -----------------------------------------------------------------
    // Verify migration completed and wallet is on home screen
    // -----------------------------------------------------------------

    // Should be on home screen
    expect(find.byType(HomeScreen), findsOne);

    // Should display the default wallet name "Main Wallet"
    expect(find.text('Main Wallet'), findsOneWidget);

    // Verify legacy mnemonic was migrated (should be deleted)
    final legacyMnemonicResult =
        await mockStorage.get(StorageKeys.legacyMnemonic);
    expect(legacyMnemonicResult.$1, isNotNull,
        reason: 'Legacy mnemonic should not be deleted after migration');

    // -----------------------------------------------------------------
    // Verify stored wallets
    // -----------------------------------------------------------------

    // Get the ProviderContainer from the ProviderScope
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    final storedWalletsState =
        await container.read(storedWalletsProvider.future);

    // Verify wallet state is not null
    expect(storedWalletsState, isNotNull,
        reason: 'Wallet state should not be null');

    // Should have exactly one wallet
    expect(storedWalletsState.wallets.length, 1,
        reason: 'Should have exactly one wallet after migration');

    final wallet = storedWalletsState.wallets.first;

    // Verify wallet name
    expect(wallet.name, 'Main Wallet',
        reason: 'Wallet should have default name "Main Wallet"');

    // Verify the mnemonic was saved with the new wallet-specific key
    final migratedMnemonicResult =
        await mockStorage.get(StorageKeys.mnemonic(wallet.id));
    expect(migratedMnemonicResult.$1, testMnemonic,
        reason: 'Mnemonic should be saved with wallet-specific key');

    // Verify current wallet is set
    expect(storedWalletsState.currentWallet, isNotNull,
        reason: 'Current wallet should be set');
    expect(storedWalletsState.currentWallet!.id, wallet.id,
        reason: 'Current wallet should match the migrated wallet');
  });
}
