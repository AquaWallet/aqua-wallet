import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/secure_storate_mocks.dart';

void main() {
  const testMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  const testWalletId = 'testwallet';

  testWidgets('Receive bitcoin flow - set amount in sats', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    // Set up mock secure storage with new multi-wallet format
    final mockStorage = MockSecureStorage();

    // Create wallet list with test wallet
    final testWallet = StoredWallet(
      id: testWalletId,
      name: 'Test Wallet',
      createdAt: DateTime.now(),
    );
    final walletsJson = jsonEncode([testWallet.toJson()]);

    // Set up stored wallets list
    mockStorage.setMockData(kStoredWalletsListKey, (walletsJson, null));

    // Set up current wallet ID
    mockStorage.setMockData(StorageKeys.currentWalletId, (testWalletId, null));

    // Set up mnemonic for the wallet
    mockStorage.setMockData(
      StorageKeys.mnemonic(testWalletId),
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

    // Trigger frames to allow app initialization to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // -----------------------------------------------------------------
    // Home screen
    // -----------------------------------------------------------------

    expect(find.byType(HomeScreen), findsOne);

    final receiveButton = find.byKey(ReceiveAssetKeys.homeScreenReceiveButton);
    expect(receiveButton, findsOneWidget);
    await tester.tap(receiveButton);
    await tester.pumpAndSettle();

    expect(find.byType(ReceiveMenuScreen), findsOne);

    final receiveBitcoinButton = find.text('Bitcoin');
    expect(receiveBitcoinButton, findsOneWidget);
    await tester.tap(receiveBitcoinButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Receive Asset screen
    // -----------------------------------------------------------------

    expect(find.byType(ReceiveAssetScreen), findsOne);

    final initialQRCodeWidget =
        tester.widget(find.byKey(ReceiveAssetKeys.receiveAssetQrCodeContainer));
    expect(initialQRCodeWidget, isNotNull);

    final setAmountButton =
        find.byKey(ReceiveAssetKeys.receiveAssetSetAmountButton);
    expect(setAmountButton, findsOneWidget);
    await tester.tap(setAmountButton);
    await tester.pumpAndSettle();

    final numpadOneButton = find.text('1');
    expect(numpadOneButton, findsOneWidget);

    await tester.tap(numpadOneButton);
    await tester.pumpAndSettle();

    final inputCurrencyConfirmButton =
        find.byKey(ReceiveAssetKeys.receiveAssetConfirmButton);
    expect(inputCurrencyConfirmButton, findsOneWidget);
    await tester.tap(inputCurrencyConfirmButton);
    await tester.pumpAndSettle();

    final updatedQRCodeWidget =
        tester.widget(find.byKey(ReceiveAssetKeys.receiveAssetQrCodeContainer));
    expect(updatedQRCodeWidget, isNotNull);

    expect(find.byType(ReceiveAssetScreen), findsOne);
  });
}
