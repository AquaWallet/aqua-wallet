import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_pop_result.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks/mocks.dart';

class MockBalanceService extends Mock implements BalanceService {}

void main() {
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
    test('parses MoneyBadger QR code successfully', () async {
      // Arrange - Remove the @ prefix as it's not part of the valid Zapper QR format
      const zapperQrCode =
          'http://2.zap.pe?t=6&i=40895:49955:7[34|29.99|11,33n|REF12345|10:10[39|ZAR,38|DillonDev';
      const expectedAddress =
          'http%3A%2F%2F2.zap.pe%3Ft%3D6%26i%3D40895%3A49955%3A7%5B34%7C29.99%7C11%2C33n%7CREF12345%7C10%3A10%5B39%7CZAR%2C38%7CDillonDev@cryptoqr.net';

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
      final result = await provider.parseQrAddressScan(zapperQrCode);

      // Assert
      expect(result, isNotNull);
      expect(result, isA<QrScannerPopSendResult>());

      final sendResult = result as QrScannerPopSendResult;
      expect(sendResult.parsedAddress.asset, equals(Asset.lightning()));
      // The address should be the URL-encoded version with @cryptoqr.net domain
      expect(sendResult.parsedAddress.address, equals(expectedAddress));
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
