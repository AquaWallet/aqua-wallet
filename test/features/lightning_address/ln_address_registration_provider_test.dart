import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/models/api_models.dart';
import 'package:aqua/features/account/providers/jan3_auth_provider.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/lightning_address/providers/ln_address_registration_provider.dart';
import 'package:aqua/features/lightning_address/services/services.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/jan3_api_lightning_addresses_mocks.dart';
import '../../mocks/liquid_provider_mocks.dart';

// --- Test constants ---

const _testWalletId = 'e238514b';

final _testWallet = StoredWallet(
  id: _testWalletId,
  name: 'Test Wallet',
  createdAt: DateTime(2024),
);

ProfileResponse _testProfile({
  int newAddressesNeeded = 3,
  String? lnUsername = 'testuser',
  String? fingerprint,
  bool lnAddressToggled = true,
  bool lnAddressGiftOpened = true,
}) =>
    ProfileResponse(
      id: 'test-id',
      email: 'test@test.com',
      lnUsername: lnUsername,
      lnAddressToggled: lnAddressToggled,
      lnAddressGiftOpened: lnAddressGiftOpened,
      newAddressesNeeded: newAddressesNeeded,
      fingerprint: fingerprint,
      lastLogin: DateTime.now(),
      isSuperuser: false,
      isStaff: false,
      isActive: true,
      dateJoined: DateTime.now(),
      groups: const [],
      userPermissions: const [],
    );

// --- Helpers ---

class FakeRegisterAddressesRequest extends Fake
    implements RegisterAddressesRequest {}

void main() {
  late ProviderContainer container;
  late MockLiquidProvider mockLiquid;
  late MockJan3ApiLightningAddresses mockApi;

  setUpAll(() {
    registerFallbackValue(FakeRegisterAddressesRequest());
  });

  setUp(() {
    mockLiquid = MockLiquidProvider();
    mockApi = MockJan3ApiLightningAddresses();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({
    required ProfileResponse profile,
    StoredWallet? currentWallet,
    bool hasWallet = true,
  }) {
    final effectiveWallet = hasWallet ? (currentWallet ?? _testWallet) : null;
    return ProviderContainer(overrides: [
      lnAddressRemoteFlagProvider.overrideWithValue(true),
      liquidProvider.overrideWithValue(mockLiquid),
      jan3ApiLightningAddressesProvider.overrideWith((_) => mockApi),
      jan3AuthProvider.overrideWith(() => _FakeJan3AuthNotifier(profile)),
      storedWalletsProvider.overrideWith(
        () => _FakeStoredWalletsNotifier(effectiveWallet),
      ),
    ]);
  }

  void arrangeSuccessfulRegistration({int addressCount = 1}) {
    mockApi.mockRegisterAddressesSuccess();

    var callCount = 0;
    when(() => mockLiquid.getReceiveAddress()).thenAnswer((_) async {
      callCount++;
      return GdkReceiveAddressDetails(address: 'lq1address$callCount');
    });
  }

  group('build guard conditions', () {
    test('does not register when newAddressesNeeded is 0', () async {
      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 0),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verifyNever(() => mockLiquid.getReceiveAddress());
    });

    test('does not register when lnUsername is null', () async {
      container = createContainer(
        profile: _testProfile(lnUsername: null),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verifyNever(() => mockLiquid.getReceiveAddress());
    });

    test('does not register when lnUsername is empty', () async {
      container = createContainer(
        profile: _testProfile(lnUsername: ''),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verifyNever(() => mockLiquid.getReceiveAddress());
    });

    test('does not register when no current wallet', () async {
      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 3),
        hasWallet: false,
      );

      await container.read(lnAddressRegistrationProvider.future);

      verifyNever(() => mockLiquid.getReceiveAddress());
    });

    test('does not register when lnAddressToggled is false', () async {
      container = createContainer(
        profile: _testProfile(
          newAddressesNeeded: 3,
          lnAddressToggled: false,
        ),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verifyNever(() => mockLiquid.getReceiveAddress());
    });
  });

  group('wallet ref mismatch', () {
    test('skips registration when fingerprint does not match wallet', () async {
      container = createContainer(
        profile: _testProfile(
          newAddressesNeeded: 3,
          fingerprint:
              'different_wallet_ref_from_backend_that_does_not_match_00',
        ),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verifyNever(() => mockLiquid.getReceiveAddress());
    });

    test('proceeds normally when fingerprint is null', () async {
      arrangeSuccessfulRegistration();

      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 1, fingerprint: null),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verify(() => mockApi.registerAddresses(
            any(),
            overrideFingerprint: any(named: 'overrideFingerprint'),
          )).called(1);
    });

    test('proceeds normally when fingerprint matches wallet', () async {
      arrangeSuccessfulRegistration();

      container = createContainer(
        profile: _testProfile(
          newAddressesNeeded: 1,
          fingerprint: _testWalletId,
        ),
      );

      await container.read(lnAddressRegistrationProvider.future);

      verify(() => mockApi.registerAddresses(
            any(),
            overrideFingerprint: any(named: 'overrideFingerprint'),
          )).called(1);
    });
  });

  group('_generateLnAddresses', () {
    test('generates the requested number of addresses', () async {
      arrangeSuccessfulRegistration();

      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 3),
      );

      await container.read(lnAddressRegistrationProvider.future);

      final captured = verify(() => mockApi.registerAddresses(
            captureAny(),
            overrideFingerprint: any(named: 'overrideFingerprint'),
          )).captured;
      final request = captured.first as RegisterAddressesRequest;

      expect(request.addresses, hasLength(3));
      expect(request.addresses, ['lq1address1', 'lq1address2', 'lq1address3']);
    });

    test('skips null addresses from getReceiveAddress', () async {
      mockApi.mockRegisterAddressesSuccess();

      var callCount = 0;
      when(() => mockLiquid.getReceiveAddress()).thenAnswer((_) async {
        callCount++;
        if (callCount == 2) return const GdkReceiveAddressDetails();
        return GdkReceiveAddressDetails(address: 'lq1address$callCount');
      });

      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 3),
      );

      await container.read(lnAddressRegistrationProvider.future);

      final captured = verify(() => mockApi.registerAddresses(
            captureAny(),
            overrideFingerprint: any(named: 'overrideFingerprint'),
          )).captured;
      final request = captured.first as RegisterAddressesRequest;

      expect(request.addresses, hasLength(2));
      expect(request.addresses, ['lq1address1', 'lq1address3']);
    });
  });

  group('_registerAddresses API call', () {
    test('sends correct request body to API', () async {
      arrangeSuccessfulRegistration();

      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 1),
      );

      await container.read(lnAddressRegistrationProvider.future);

      final captured = verify(() => mockApi.registerAddresses(
            captureAny(),
            overrideFingerprint: any(named: 'overrideFingerprint'),
          )).captured;
      final request = captured.first as RegisterAddressesRequest;

      expect(request.fingerPrint, equals(_testWalletId));
      expect(request.addresses, ['lq1address1']);
    });

    test('sets error state when API returns error', () async {
      mockLiquid.mockGetReceiveAddress(address: 'lq1address1');
      mockApi.mockRegisterAddressesFailure(
        statusCode: 400,
        body: 'Invalid Liquid address',
      );

      container = createContainer(
        profile: _testProfile(newAddressesNeeded: 1),
      );

      await expectLater(
        container.read(lnAddressRegistrationProvider.future),
        throwsA(isA<Exception>()),
      );

      final state = container.read(lnAddressRegistrationProvider);
      expect(state.hasError, isTrue);
    });
  });

  group('forceRegisterAddresses', () {
    test('registers when lnAddressToggled is false and newAddressesNeeded is 0',
        () async {
      arrangeSuccessfulRegistration(addressCount: 5);

      container = createContainer(
        profile: _testProfile(
          newAddressesNeeded: 0,
          lnAddressToggled: false,
        ),
      );

      await container.read(lnAddressRegistrationProvider.notifier).activate();

      final captured = verify(() => mockApi.registerAddresses(
            captureAny(),
            overrideFingerprint: any(named: 'overrideFingerprint'),
          )).captured;
      final request = captured.first as RegisterAddressesRequest;

      expect(request.addresses, hasLength(5));
    });
  });
}

// --- Fake Notifiers ---
class _FakeJan3AuthNotifier extends FamilyAsyncNotifier<Jan3AuthState, String>
    implements Jan3AuthNotifier {
  final ProfileResponse _profile;

  _FakeJan3AuthNotifier(this._profile);

  @override
  Future<Jan3AuthState> build(String arg) async =>
      Jan3AuthState.authenticated(profile: _profile);

  @override
  Future<void> refreshAfterRebind() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStoredWalletsNotifier extends AsyncNotifier<WalletState>
    implements StoredWalletsNotifier {
  final StoredWallet? _currentWallet;

  _FakeStoredWalletsNotifier(this._currentWallet);

  @override
  Future<WalletState> build() async => WalletState(
        wallets: [if (_currentWallet != null) _currentWallet],
        currentWallet: _currentWallet,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
