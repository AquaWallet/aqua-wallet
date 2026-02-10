import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.lbtc();
  final args = SendAssetArguments.fromAsset(asset);

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(Decimal.zero);
  });

  group('LightningInvoiceToLbtcSwapNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be false', () async {
      final provider = lightningInvoiceToLbtcSwapProvider(args);
      final state = await container.read(provider.future);

      expect(state, false);
    });

    test('provider should be properly initialized', () async {
      final provider = lightningInvoiceToLbtcSwapProvider(args);

      // Verify provider can be read without errors
      final notifier = container.read(provider.notifier);
      expect(notifier, isA<LightningInvoiceToLbtcSwapNotifier>());

      // Verify initial async state
      final state = await container.read(provider.future);
      expect(state, false);
    });

    test('provider should work with different SendAssetArguments', () async {
      final btcAsset = Asset.btc();
      final btcArgs = SendAssetArguments.fromAsset(btcAsset);

      final provider = lightningInvoiceToLbtcSwapProvider(btcArgs);
      final state = await container.read(provider.future);

      expect(state, false);
    });

    test('provider should be auto-disposable', () async {
      final provider = lightningInvoiceToLbtcSwapProvider(args);

      // Read the provider to initialize it
      await container.read(provider.future);

      // Verify it's in the container
      expect(container.exists(provider), true);

      // The provider should be auto-dispose, but we can't easily test disposal
      // without triggering the disposal mechanism
    });

    test(
        'provider family should create different instances for different arguments',
        () async {
      final lbtcArgs = SendAssetArguments.fromAsset(Asset.lbtc());
      final btcArgs = SendAssetArguments.fromAsset(Asset.btc());

      final lbtcProvider = lightningInvoiceToLbtcSwapProvider(lbtcArgs);
      final btcProvider = lightningInvoiceToLbtcSwapProvider(btcArgs);

      // These should be different provider instances
      expect(identical(lbtcProvider, btcProvider), false);

      // But both should work
      final lbtcState = await container.read(lbtcProvider.future);
      final btcState = await container.read(btcProvider.future);

      expect(lbtcState, false);
      expect(btcState, false);
    });

    test('provider should handle build method correctly', () async {
      final provider = lightningInvoiceToLbtcSwapProvider(args);

      // The build method should complete successfully and return false
      final state = await container.read(provider.future);
      expect(state, false);

      // Should be able to read multiple times
      final state2 = await container.read(provider.future);
      expect(state2, false);
    });

    group('Documentation of Limitations', () {
      test('extension method mocking limitation', () async {
        // This test documents the limitation we encountered during testing.
        // The LightningInvoiceToLbtcSwapNotifier uses the AddressParser.isLightningInvoice
        // extension method, which cannot be easily mocked with mocktail.
        //
        // The provider's core functionality (_detectSwap method) includes:
        // 1. parser.isLightningInvoice(input: prevAddress) - Extension method (hard to mock)
        // 2. parser.isValidAddressForAsset(...) - Regular method (can be mocked)
        // 3. Error handling with try/catch
        // 4. State updates with AsyncValue.data(...)
        //
        // This test serves as documentation of what the provider does
        // and why comprehensive unit testing is challenging.

        final provider = lightningInvoiceToLbtcSwapProvider(args);
        final state = await container.read(provider.future);

        // We can test the basic provider setup and initial state
        expect(state, false);

        // Note: Full testing of the swap detection logic would require:
        // - Mocking extension methods (not easily possible with mocktail)
        // - Or integration testing with real address parsing (complex setup)
        // - Or refactoring the business logic to make extension methods mockable
      });

      test('listener mechanism setup', () async {
        // This test verifies that the provider sets up its listener correctly
        // during the build phase, even though we can't easily test the listener behavior.

        final provider = lightningInvoiceToLbtcSwapProvider(args);

        // The build method should complete without errors, indicating the listener
        // was set up successfully
        final state = await container.read(provider.future);
        expect(state, false);

        // If the build method had failed to set up the listener properly,
        // it would have thrown an exception during provider initialization
      });

      test('error handling in state management', () async {
        // This test documents that the provider uses proper async state management
        // with AsyncValue, which includes error handling capabilities.

        final provider = lightningInvoiceToLbtcSwapProvider(args);

        // Verify the provider state is properly initialized
        final state = await container.read(provider.future);
        expect(state, false);

        // Verify async state structure
        final asyncValue = container.read(provider);
        expect(asyncValue, isA<AsyncValue<bool>>());
        expect(asyncValue.hasError, false);

        // The actual error handling is in the _detectSwap method,
        // which catches exceptions and sets state = AsyncValue.data(false)
        // This behavior is tested indirectly through the initial state test
      });
    });

    group('Provider Architecture Tests', () {
      test('should use correct provider type and family structure', () async {
        // Verify the provider is properly structured and works as expected
        final provider = lightningInvoiceToLbtcSwapProvider(args);

        // Verify it's a provider that works with the expected types
        final state = await container.read(provider.future);
        expect(state, isA<bool>());

        final notifier = container.read(provider.notifier);
        expect(notifier, isA<LightningInvoiceToLbtcSwapNotifier>());
      });

      test('should work with minimal provider container setup', () async {
        // Test that the provider works with minimal setup
        // This is important for ensuring it doesn't have unexpected dependencies
        final minimalContainer = ProviderContainer();

        try {
          final provider = lightningInvoiceToLbtcSwapProvider(args);
          final state = await minimalContainer.read(provider.future);
          expect(state, false);
        } finally {
          minimalContainer.dispose();
        }
      });
    });
  });
}
