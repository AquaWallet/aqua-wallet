import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua/features/home/home.dart';

void main() {
  testWidgets('Create and delete flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    // Load app widget.
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        child: const AquaApp()));

    // Trigger a frame.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // -----------------------------------------------------------------
    // Welcome screen
    // -----------------------------------------------------------------
    final createButton = find.byKey(const Key('welcome-create-btn'));
    expect(createButton, findsOneWidget);

    final restoreButton = find.byKey(const Key('welcome-restore-btn'));
    expect(restoreButton, findsOneWidget);

    final tosCheckbox = find.byKey(const Key('welcome-tos-checkbox'));
    expect(tosCheckbox, findsOneWidget);

    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('welcome-unaccepted-condition')), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(tosCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

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

    final deleteWalletBtn = find.byKey(const Key('remove-wallet'));
    await tester.dragUntilVisible(
        deleteWalletBtn, settingsScreen, const Offset(-250, 0));
    expect(deleteWalletBtn, findsOneWidget);
    await tester.tap(deleteWalletBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RemoveWalletConfirmScreen), findsOne);
    final actionButtons = find.byType(AquaElevatedButton);
    expect(actionButtons, findsExactly(2));

    await tester.tap(actionButtons.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
