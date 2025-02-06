import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/settings/manage_assets/keys/manage_assets_screen_keys.dart';
import 'package:aqua/features/wallet/keys/wallet_keys.dart';
import 'package:aqua/features/shared/keys/shared_keys.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/settings/shared/pages/settings_tab.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/common/keys/common_keys.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua/features/home/home.dart';
import '../mocks/secure_storate_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
  });

  // -----------------------------------------------------------------
  // Test DISABLED due to bug: https://github.com/jan3dev/aqua-dev/issues/1548
  // -----------------------------------------------------------------
  testWidgets('Manage Assets scenario - disable and enable USDt',
      (tester) async {
    String tetherUsdt = 'Tether USDt';
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    // Load app widget.
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      secureStorageProvider.overrideWithValue(mockSecureStorage)
    ], child: const AquaApp()));

    await tester.pumpAndSettle(const Duration(seconds: 5));

    // -----------------------------------------------------------------
    // Home screen
    // -----------------------------------------------------------------

    expect(find.byType(HomeScreen), findsOne);

    var settingsButton = find.byKey(CommonKeys.settingsButton);
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Settings screen
    // -----------------------------------------------------------------

    expect(find.byType(SettingsTab), findsOne);

    var manageAssetsButton =
        find.byKey(SettingsScreenKeys.settingsManageAssetsButton);

    await tester.ensureVisible(manageAssetsButton);
    await tester.pumpAndSettle();
    expect(manageAssetsButton, findsOneWidget);
    await tester.tap(manageAssetsButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Manage screen
    // -----------------------------------------------------------------

    expect(find.byType(ManageAssetsScreen), findsOne);

    await tapAssetOptionButton(
      tester,
      buttonKey: ManageAssetsScreenKeys.manageAssetRemoveButton,
      assetText: tetherUsdt,
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tapBackButton(tester);

    // -----------------------------------------------------------------
    // Home screen
    // -----------------------------------------------------------------

    var walletButton = find.byKey(CommonKeys.walletButton);
    expect(walletButton, findsOneWidget);
    await tester.tap(walletButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var asset = find.text(tetherUsdt);
    expect(asset, findsNothing);

    await verifyButtonNavigationAndNoAsset(
      tester,
      buttonKey: WalletKeys.homeReceiveButton,
      expectedScreenType: TransactionMenuScreen,
      isPresent: false,
      assetText: tetherUsdt,
    );

    await verifyButtonNavigationAndNoAsset(
      tester,
      buttonKey: WalletKeys.homeSendButton,
      expectedScreenType: TransactionMenuScreen,
      isPresent: false,
      assetText: tetherUsdt,
    );

    await tapBackButton(tester);

    settingsButton = find.byKey(CommonKeys.settingsButton);
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Settings screen
    // -----------------------------------------------------------------

    expect(find.byType(SettingsTab), findsOne);

    manageAssetsButton =
        find.byKey(SettingsScreenKeys.settingsManageAssetsButton);
    await tester.ensureVisible(manageAssetsButton);
    expect(manageAssetsButton, findsOneWidget);
    await tester.tap(manageAssetsButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Manage screen
    // -----------------------------------------------------------------

    expect(find.byType(ManageAssetsScreen), findsOne);

    final addAssetButton =
        find.byKey(ManageAssetsScreenKeys.manageAssetAddAssetButton);
    expect(addAssetButton, findsOneWidget);
    await tester.tap(addAssetButton);
    await tester.pumpAndSettle();

    await tapAssetOptionButton(
      tester,
      buttonKey: ManageAssetsScreenKeys.manageAssetAddSpecificAssetButton,
      assetText: tetherUsdt,
    );

    await tapBackButton(tester);
    expect(find.byType(ManageAssetsScreen), findsOne);

    asset = find.text(tetherUsdt);
    expect(asset, findsOneWidget);

    await tapBackButton(tester);

    walletButton = find.byKey(CommonKeys.walletButton);
    expect(walletButton, findsOneWidget);
    await tester.tap(walletButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Home screen
    // -----------------------------------------------------------------

    asset = find.text(tetherUsdt);
    expect(asset, findsOneWidget);

    await verifyButtonNavigationAndNoAsset(
      tester,
      buttonKey: WalletKeys.homeReceiveButton,
      expectedScreenType: TransactionMenuScreen,
      isPresent: true,
      assetText: tetherUsdt,
    );

    await verifyButtonNavigationAndNoAsset(
      tester,
      buttonKey: WalletKeys.homeSendButton,
      expectedScreenType: TransactionMenuScreen,
      isPresent: true,
      assetText: tetherUsdt,
    );
  }, skip: true);
}

Future<void> tapAssetOptionButton(
  WidgetTester tester, {
  required Key buttonKey,
  required String assetText,
}) async {
  final textFinder = find.text(assetText);
  expect(textFinder, findsOneWidget);
  final addButtonFinder = find.descendant(
    of: find.ancestor(
      of: textFinder,
      matching: find.byType(Row),
    ),
    matching: find.byKey(buttonKey),
  );
  expect(addButtonFinder, findsOneWidget);
  await tester.tap(addButtonFinder);
}

Future<void> tapBackButton(WidgetTester tester) async {
  final backButton = find.byKey(SharedScreenKeys.sharedBackButton);
  expect(backButton, findsOneWidget);
  await tester.tap(backButton);
  await tester.pumpAndSettle();
}

Future<void> verifyButtonNavigationAndNoAsset(
  WidgetTester tester, {
  required Key buttonKey,
  required Type expectedScreenType,
  required bool isPresent,
  required String assetText,
}) async {
  final button = find.byKey(buttonKey);
  expect(button, findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(expectedScreenType), findsOne);

  final asset = find.text(assetText);
  if (isPresent) {
    expect(asset, findsOneWidget);
  } else {
    expect(asset, findsNothing);
  }
}
