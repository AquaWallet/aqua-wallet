import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/onboarding/keys/onboarding_screen_keys.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Restore flow', (tester) async {
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

    final restoreButton = find.byKey(OnboardingScreenKeys.welcomeRestoreButton);
    expect(restoreButton, findsOneWidget);

    final tosCheckbox = find.byKey(OnboardingScreenKeys.welcomeTosCheckbox);
    expect(tosCheckbox, findsOneWidget);

    await tester.tap(tosCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // -----------------------------------------------------------------
    // Restore start screen
    // -----------------------------------------------------------------
    expect(find.text('Get your seed phrase ready'), findsOneWidget);
    final continueButton = find.text('Start');
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------
    // Restore input screen
    // -----------------------------------------------------------------
    expect(find.text('Enter the seed phrase'), findsOneWidget);

    final mneInputFinder = find.byType(WalletRestoreInputField);
    final restoreActionButton = find.byType(AquaElevatedButton);

    expect(mneInputFinder, findsExactly(kMnemonicLength));
    expect(restoreActionButton, findsOne);

    // fill 12 words
    await tester.enterText(mneInputFinder.at(0), 'filter');
    await tester.enterText(mneInputFinder.at(1), 'business');
    await tester.enterText(mneInputFinder.at(2), 'whip');
    await tester.enterText(mneInputFinder.at(3), 'tray');
    await tester.enterText(mneInputFinder.at(4), 'vacant');
    await tester.enterText(mneInputFinder.at(5), 'ritual');
    await tester.enterText(mneInputFinder.at(6), 'beef');
    await tester.enterText(mneInputFinder.at(7), 'gallery');
    await tester.enterText(mneInputFinder.at(8), 'bottom');
    await tester.enterText(mneInputFinder.at(9), 'crucial');
    await tester.enterText(mneInputFinder.at(10), 'speed');
    await tester.enterText(mneInputFinder.at(11), 'liar');
    await tester.pump();

    await tester.tap(restoreActionButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(HomeScreen), findsOne);
  });
}
