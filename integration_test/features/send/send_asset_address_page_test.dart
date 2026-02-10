import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test/mocks/mocks.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences sp = await SharedPreferences.getInstance();

  setUpAll(() async {
    registerFallbackValue(Asset.unknown());
  });

  group('On screen start', () {
    final btcAsset = Asset.btc();
    final lbtcAsset = Asset.lbtc();
    final args = SendAssetArguments.fromAsset(btcAsset);
    final mockAddressParser = MockAddressParserProvider();
    final mockManageAssetsProvider = MockManageAssetsProvider();
    final mockBitcoinProvider = MockBitcoinProvider();
    final mockBalanceProvider = MockBalanceProvider();
    final mockPrefsProvider = MockUserPreferencesNotifier();
    final mockAquaProvider = MockAquaProvider();

    final app = ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        assetsProvider.overrideWith(
            () => MockAssetsNotifier(assets: [btcAsset, lbtcAsset])),
        clipboardContentProvider.overrideWith((_) => Future.value(null)),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        aquaProvider.overrideWith((_) => mockAquaProvider),
        // Start the test on the send asset screen
        routerProvider.overrideWith(
          (_) => GoRouter(
            initialLocation: SendAssetScreen.routeName,
            routes: [
              GoRoute(
                path: SendAssetScreen.routeName,
                builder: (_, __) => SendAssetScreen(arguments: args),
              ),
            ],
          ),
        )
      ],
      child: const AquaApp(),
    );

    testWidgets(
      'Address field is empty AND continue button disabled',
      (tester) async {
        mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
        mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
        mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
        mockPrefsProvider.mockGetDarkModeCall(false);
        mockPrefsProvider.mockGetBotevModeCall(false);
        mockAddressParser.mockIsValidAddressForAssetCall(value: true);
        mockAquaProvider.mockClearSecureStorageOnReinstall();

        await tester.pumpWidget(app);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final addressPage = find.byType(SendAssetAddressPage);
        expect(addressPage, findsOneWidget);

        final addressField = find.byType(AddressInputView);
        expect(addressField, findsOneWidget);

        final textField = find.descendant(
          of: addressField,
          matching: find.byType(TextField),
        );
        expect(textField, findsOneWidget);
        expect(tester.widget<TextField>(textField).controller?.text, isEmpty);

        final button = find.byKey(SendKeys.sendContinueButton);
        expect(button, findsOneWidget);
      },
    );

    testWidgets(
      'Should verify address and amount send before sending transtaction',
      (tester) async {
        mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
        mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
        mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
        mockPrefsProvider.mockGetDarkModeCall(false);
        mockPrefsProvider.mockGetBotevModeCall(false);
        mockAddressParser.mockIsValidAddressForAssetCall(value: true);
        mockAquaProvider.mockClearSecureStorageOnReinstall();
        mockAddressParser.mockParseInputCall(
          value: ParsedAddress(
            asset: btcAsset,
            address: kFakeBitcoinAddress,
            amountInSats: kOneBtcInSats,
          ),
        );
        const amountSend = '0.001';

        await tester.pumpWidget(app);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final addressPage = find.byType(SendAssetAddressPage);
        expect(addressPage, findsOneWidget);

        final addressField = find.byType(AddressInputView);
        expect(addressField, findsOneWidget);

        final textField = find.descendant(
          of: addressField,
          matching: find.byType(TextField),
        );
        expect(textField, findsOneWidget);

        final controller = tester.widget<TextField>(textField).controller;
        expect(controller?.text, isEmpty);

        await tester.enterText(textField, kFakeBitcoinAddress);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(controller?.text, isNotEmpty);

        final errorText = find.byKey(SendKeys.sendErrorTextMessage);
        expect(errorText, findsNothing);

        final button = find.byKey(SendKeys.sendContinueButton);
        expect(button, findsOneWidget);

        await tester.tap(button);
        await tester.pumpAndSettle();

        final assetInput = find.byKey(SendKeys.sendAssetInput);
        await tester.enterText(assetInput, amountSend);
        await tester.pumpAndSettle();

        await tester.tap(button);
        await tester.pumpAndSettle();

        final sendAssetReviewPage = find.byType(SendAssetReviewPage);
        expect(sendAssetReviewPage, findsOneWidget);

        final sendAssetAddress = find.byKey(SendKeys.sendToAddressValue);
        final sendAssetTexts = find
            .descendant(
              of: sendAssetAddress,
              matching: find.byType(Text),
            )
            .evaluate()
            .toList();
        final sendAssetText = sendAssetTexts[1].widget as Text;
        expect(sendAssetText.data, kFakeBitcoinAddress);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final assetCryptoAmountText = tester.widget<RichText>(find.descendant(
          of: find.byKey(SendKeys.assetCryptoAmount),
          matching: find.byType(RichText),
        ));

        expect((assetCryptoAmountText.text as TextSpan).toPlainText(),
            "${amountSend}00000 ${btcAsset.ticker}");
      },
    );
  });
}
