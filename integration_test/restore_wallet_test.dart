import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper to type using virtual keyboard and optionally tap suggestion
  Future<void> typeWord(
    WidgetTester tester,
    Finder inputFinder,
    String charsToType,
    String? suggestionToTap,
  ) async {
    // Tap on the input field to focus it
    await tester.tap(inputFinder);
    await tester.pumpAndSettle();

    // Type each letter by tapping on the virtual keyboard
    for (final char in charsToType.split('')) {
      final keyFinder = find.text(char);
      expect(keyFinder, findsWidgets);
      await tester.tap(keyFinder.last);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Tap suggestion if provided
    if (suggestionToTap != null) {
      final suggestionFinder = find.text(suggestionToTap.toLowerCase());
      expect(suggestionFinder, findsOneWidget);
      await tester.tap(suggestionFinder);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('Restore flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    // Load app widget.
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        child: const AquaApp()));

    // Trigger a frame.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // -----------------------------------------------------------------
    // Welcome screen
    // -----------------------------------------------------------------

    final restoreButton = find.byKey(OnboardingScreenKeys.welcomeRestoreButton);
    expect(restoreButton, findsOneWidget);

    await tester.tap(restoreButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // -----------------------------------------------------------------
    // Restore start screen
    // -----------------------------------------------------------------
    final startButton = find.byKey(OnboardingScreenKeys.restoreStartButton);
    expect(startButton, findsOneWidget);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Restore input screen (Page 1 - words 1-4)
    // -----------------------------------------------------------------
    // Mnemonic: filter business whip tray vacant ritual beef gallery bottom crucial speed liar
    // Type partial words to trigger unique suggestions

    var mneInputFinder = find.byType(WalletRestoreInputField);
    expect(mneInputFinder, findsExactly(4)); // Only 4 fields per page

    // Fill first 4 words using virtual keyboard + suggestions
    await typeWord(tester, mneInputFinder.at(0), 'filt', 'filter');
    await typeWord(tester, mneInputFinder.at(1), 'busi', 'business');
    await typeWord(tester, mneInputFinder.at(2), 'whi', 'whip');
    await typeWord(
        tester, mneInputFinder.at(3), 'tray', null); // type full word

    // Tap "Next" button to go to page 2
    var nextButton = find.byKey(OnboardingScreenKeys.restoreNextButton);
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Restore input screen (Page 2 - words 5-8)
    // -----------------------------------------------------------------
    mneInputFinder = find.byType(WalletRestoreInputField);
    expect(mneInputFinder, findsExactly(4));

    // Fill next 4 words using virtual keyboard + suggestions
    await typeWord(tester, mneInputFinder.at(0), 'vac', 'vacant');
    await typeWord(tester, mneInputFinder.at(1), 'ritu', 'ritual');
    await typeWord(tester, mneInputFinder.at(2), 'bee', 'beef');
    await typeWord(tester, mneInputFinder.at(3), 'gall', 'gallery');

    // Tap "Next" button to go to page 3
    nextButton = find.byKey(OnboardingScreenKeys.restoreNextButton);
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Restore input screen (Page 3 - words 9-12)
    // -----------------------------------------------------------------
    mneInputFinder = find.byType(WalletRestoreInputField);
    expect(mneInputFinder, findsExactly(4));

    // Fill last 4 words using virtual keyboard + suggestions
    await typeWord(tester, mneInputFinder.at(0), 'bott', 'bottom');
    await typeWord(tester, mneInputFinder.at(1), 'cruc', 'crucial');
    await typeWord(tester, mneInputFinder.at(2), 'spee', 'speed');
    await typeWord(tester, mneInputFinder.at(3), 'lia', 'liar');

    // Tap "Next" button on final page to go to review screen
    nextButton = find.byKey(OnboardingScreenKeys.restoreNextButton);
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // -----------------------------------------------------------------
    // Restore review screen - tap Restore button
    // -----------------------------------------------------------------
    final restoreConfirmButton =
        find.byKey(OnboardingScreenKeys.restoreConfirmButton);
    expect(restoreConfirmButton, findsOneWidget);
    await tester.tap(restoreConfirmButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // -----------------------------------------------------------------
    // Wallet name input screen
    // -----------------------------------------------------------------
    // After validation, user is prompted to enter wallet name
    final walletNameField = find.byKey(OnboardingScreenKeys.walletNameInput);
    expect(walletNameField, findsOneWidget);
    await tester.enterText(walletNameField, 'Test Wallet');
    await tester.pumpAndSettle();

    // Tap save/confirm button
    final saveButton = find.byKey(OnboardingScreenKeys.walletNameSaveButton);
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOne);
  });
}
