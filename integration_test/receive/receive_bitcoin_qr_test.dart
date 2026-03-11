import 'package:aqua/data/data.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/keys/wallet_keys.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/secure_storate_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
  });

  testWidgets('Receive bitcoin flow - set amount in sats', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    // Load app widget.
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      secureStorageProvider.overrideWithValue(mockSecureStorage)
    ], child: const AquaApp()));

    // Trigger a frame.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // -----------------------------------------------------------------
    // Home screen
    // -----------------------------------------------------------------

    expect(find.byType(HomeScreen), findsOne);

    final receiveButton = find.byKey(WalletKeys.homeReceiveButton);
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

    final inputCurrencyField =
        find.byKey(ReceiveAssetKeys.receiveAssetSetAmountInputField);
    expect(inputCurrencyField, findsOneWidget);

    await tester.enterText(inputCurrencyField, '100');

    final inputCurrencyConfirmButton =
        find.byKey(ReceiveAssetKeys.receiveAssetConfirmButton);
    expect(inputCurrencyConfirmButton, findsOneWidget);
    await tester.tap(inputCurrencyConfirmButton);
    await tester.pumpAndSettle();

    final updatedQRCodeWidget =
        tester.widget(find.byKey(ReceiveAssetKeys.receiveAssetQrCodeContainer));
    expect(updatedQRCodeWidget, isNotNull);

    expect(find.byType(ReceiveAssetScreen), findsOne);

    final shareAddressButton =
        find.byKey(ReceiveAssetKeys.receiveAssetShareAddressButton);
    expect(shareAddressButton, findsOneWidget);
  });
}
