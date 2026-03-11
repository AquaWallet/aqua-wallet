import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/keys/onboarding_screen_keys.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  testWidgets('Create and delete flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    // Load app widget.
    await tester.pumpWidget(
      ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
          child: const AquaApp()),
    );

    // Trigger a frame.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // -----------------------------------------------------------------
    // Welcome screen
    // -----------------------------------------------------------------
    final createButton = find.byKey(OnboardingScreenKeys.welcomeCreateButton);
    expect(createButton, findsOneWidget);

    final restoreButton = find.byKey(OnboardingScreenKeys.welcomeRestoreButton);
    expect(restoreButton, findsOneWidget);

    await tester.tap(createButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final walletNameInput = find.byKey(OnboardingScreenKeys.walletNameInput);
    expect(walletNameInput, findsOneWidget);

    final walletNameSaveButton =
        find.byKey(OnboardingScreenKeys.walletNameSaveButton);
    expect(walletNameSaveButton, findsOneWidget);

    await tester.enterText(walletNameInput, "First wallet");
    await tester.pumpAndSettle();

    await tester.tap(walletNameSaveButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOne);

    final modalButtons = find.byType(AquaButton);
    if (modalButtons.evaluate().isNotEmpty) {
      await tester.tap(modalButtons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    expect(find.byType(HomeScreen), findsOne);

    // -----------------------------------------------------------------
    // Delete wallet flow
    // -----------------------------------------------------------------

    final settingsNavigationBtn = find.text('Settings');
    expect(settingsNavigationBtn, findsOneWidget);
    await tester.tap(settingsNavigationBtn);
    await tester.pumpAndSettle();

    final settingsScreen = find.byType(SettingsTab);
    expect(settingsScreen, findsOne);

    final walletSettingsButton =
        find.byKey(SettingsScreenKeys.settingsWalletButton);
    expect(walletSettingsButton, findsOne);

    await tester.tap(walletSettingsButton);
    await tester.pumpAndSettle();

    final deleteWalletBtn =
        find.byKey(SettingsScreenKeys.settingsRemoveWalletButton);
    expect(deleteWalletBtn, findsOneWidget);
    await tester.tap(deleteWalletBtn);
    await tester.pumpAndSettle();

    // The remove wallet functionality uses a modal sheet, not a separate screen
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Look for the modal buttons
    final deleteModalConfirmBtn = find.byKey(deleteWalletButtonConfirmKey);
    expect(deleteModalConfirmBtn, findsExactly(1));

    // doesn't work anymore because Restart.restartApp() breaks the test runner's connection
    // await tester.tap(deleteBtn.first);
    // await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
