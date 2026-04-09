import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_pop_result.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/address_validator/models/address_parsing_exception.dart';
import 'package:aqua/features/lightning/providers/lnurl_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
        const MoneybadgerDecodeRequest(qrData: '', isTestnet: false));
  });

  late MockLiquidProvider mockLiquidProvider;
  late MockBitcoinProvider mockBitcoinProvider;
  late MockBalanceService mockBalanceService;
  late MockUserPreferencesNotifier mockPrefsProvider;
  late MockSharedPreferences mockSharedPreferences;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockLiquidProvider = MockLiquidProvider();
    mockBitcoinProvider = MockBitcoinProvider();
    mockBalanceService = MockBalanceService();
    mockPrefsProvider = MockUserPreferencesNotifier();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockBalanceService.getLBTCBalance())
        .thenAnswer((_) async => 10000);
    when(() => mockLiquidProvider.isValidAddress(any()))
        .thenAnswer((_) async => false);
    when(() => mockBitcoinProvider.isValidAddress(any()))
        .thenAnswer((_) async => false);
    when(() => mockPrefsProvider.userAssetIds).thenReturn([]);
    when(() => mockSharedPreferences.getString(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.getStringList(any())).thenReturn(null);
  });

  tearDown(() {
    container.dispose();
  });

  group('parseQrAddressScan', () {
    test(
        'calls backend for MoneyBadger QR and throws when backend returns error',
        () async {
      // Moneybadger decoding is now handled by the Ankara backend.
      // When the backend returns an error, parsing fails with AddressParsingException.
      const zapperQrCode =
          'http://2.zap.pe?t=6&i=40895:49955:7[34|29.99|11,33n|REF12345|10:10[39|ZAR,38|DillonDev';

      final mockJan3 = MockJan3ApiService();
      mockJan3.mockDecodeMoneybadgerError();

      container = ProviderContainer(overrides: [
        liquidProvider.overrideWithValue(mockLiquidProvider),
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
        balanceProvider.overrideWithValue(mockBalanceService),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sharedPreferencesProvider.overrideWith((_) => mockSharedPreferences),
        assetsProvider.overrideWith(() => MockAssetsNotifier(assets: [])),
        jan3ApiServiceProvider.overrideWith((_) async => mockJan3),
      ]);

      final provider = container.read(qrScannerProvider(null));

      // No asset is passed, mirroring the real-world scanner flow.
      // The backend is tried as a last resort for unrecognised QR codes;
      // when it returns an error, parsing throws AddressParsingException.
      await expectLater(
        () => provider.parseQrAddressScan(zapperQrCode),
        throwsA(isA<AddressParsingException>()),
      );
      verify(() => mockJan3.decodeMoneybadger(any())).called(1);
    });

    test(
        'pre-encoded QR (with @cryptoqr.net) is handled as a lightning address, not via the backend',
        () async {
      // The URL-encoded form ends with @cryptoqr.net, so it matches the
      // lightning address format (user@domain) and goes directly through
      // _parseLightningAddress — the Moneybadger backend is never called.
      const encodedQrCode =
          'http%3A%2F%2F2.zap.pe%3Ft%3D6%26i%3D40895%3A49955%3A7%5B34%7C29.99%7C11%2C33n%7CREF12345%7C10%3A10%5B39%7CZAR%2C38%7CDillonDev@cryptoqr.net';

      final mockJan3 = MockJan3ApiService();
      final mockLnurlService = MockLnurlService();
      when(() => mockLnurlService.isValidLightningAddressFormat(any()))
          .thenReturn(true);
      when(() => mockLnurlService.convertLnAddressToWellKnown(any()))
          .thenThrow(Exception('unreachable server'));

      container = ProviderContainer(overrides: [
        liquidProvider.overrideWithValue(mockLiquidProvider),
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
        balanceProvider.overrideWithValue(mockBalanceService),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sharedPreferencesProvider.overrideWith((_) => mockSharedPreferences),
        assetsProvider.overrideWith(() => MockAssetsNotifier(assets: [])),
        jan3ApiServiceProvider.overrideWith((_) async => mockJan3),
        lnurlProvider.overrideWithValue(mockLnurlService),
      ]);

      final provider = container.read(qrScannerProvider(null));

      await expectLater(
        () => provider.parseQrAddressScan(encodedQrCode),
        throwsA(isA<AddressParsingException>()),
      );

      verifyNever(() => mockJan3.decodeMoneybadger(any()));
    });

    test('returns null when value is null', () async {
      container = ProviderContainer(overrides: [
        liquidProvider.overrideWithValue(mockLiquidProvider),
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
        balanceProvider.overrideWithValue(mockBalanceService),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sharedPreferencesProvider.overrideWith((_) => mockSharedPreferences),
        assetsProvider.overrideWith(() => MockAssetsNotifier(assets: [])),
      ]);

      final provider = container.read(qrScannerProvider(null));

      // Act
      final result = await provider.parseQrAddressScan(null);

      // Assert
      expect(result, isNull);
    });

    test('throws exception when parsing fails', () async {
      const invalidQrCode = 'invalid-qr-code';

      container = ProviderContainer(overrides: [
        liquidProvider.overrideWithValue(mockLiquidProvider),
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
        balanceProvider.overrideWithValue(mockBalanceService),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sharedPreferencesProvider.overrideWith((_) => mockSharedPreferences),
        assetsProvider.overrideWith(() => MockAssetsNotifier(assets: [])),
      ]);

      final provider = container.read(qrScannerProvider(null));

      // Act & Assert
      // Should throw an exception for invalid QR code
      expect(
        () => provider.parseQrAddressScan(invalidQrCode),
        throwsException,
      );
    });

    test('parses QR code with specific asset', () async {
      const bitcoinAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
      final btcAsset = Asset.btc();

      // Mock bitcoin provider to accept this address
      when(() => mockBitcoinProvider.isValidAddress(bitcoinAddress))
          .thenAnswer((_) async => true);

      container = ProviderContainer(overrides: [
        liquidProvider.overrideWithValue(mockLiquidProvider),
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
        balanceProvider.overrideWithValue(mockBalanceService),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sharedPreferencesProvider.overrideWith((_) => mockSharedPreferences),
        assetsProvider.overrideWith(() => MockAssetsNotifier(assets: [])),
      ]);

      final provider = container.read(qrScannerProvider(null));

      // Act
      final result = await provider.parseQrAddressScan(
        bitcoinAddress,
        asset: btcAsset,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<QrScannerPopSendResult>());

      final sendResult = result as QrScannerPopSendResult;
      expect(sendResult.parsedAddress.asset, equals(btcAsset));
      expect(sendResult.parsedAddress.address, equals(bitcoinAddress));
    });
  });
}
