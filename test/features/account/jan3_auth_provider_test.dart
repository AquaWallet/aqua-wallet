import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:aqua/features/wallet/models/wallet_state.dart';
import 'package:aqua/features/wallet/providers/stored_wallets_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/jan3_api_service_mocks.dart';
import '../../mocks/jan3_auth_token_manager_mocks.dart';
import '../../mocks/stored_wallets_provider_mocks.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const kTestWalletId = 'wallet-abc';

final kTestProfile = ProfileResponse(
  id: 'user-123',
  email: 'user@test.com',
  lastLogin: null,
  isSuperuser: false,
  isStaff: false,
  isActive: true,
  dateJoined: DateTime(2024),
  groups: [],
  userPermissions: [],
);

const kTestAuthToken = AuthTokenResponse(
  access: 'access-token',
  refresh: 'refresh-token',
);

StoredWallet makeWallet({
  ProfileResponse? profile,
  AuthTokenResponse? authToken,
}) =>
    StoredWallet(
      id: kTestWalletId,
      name: 'Test Wallet',
      createdAt: DateTime(2024),
      profileResponse: profile,
      authToken: authToken,
    );

// ---------------------------------------------------------------------------
// Container helper
// ---------------------------------------------------------------------------

ProviderContainer makeContainer({
  required FakeJan3AuthTokenManager tokenManager,
  WalletState walletState = const WalletState(wallets: []),
  Jan3ApiService? apiService,
}) {
  return ProviderContainer(overrides: [
    jan3AuthTokenManagerProvider.overrideWith((ref, id) => tokenManager),
    storedWalletsProvider.overrideWith(
        () => MockStoredWalletsNotifier(initialState: walletState)),
    if (apiService != null)
      jan3ApiServiceProvider.overrideWith((ref) async => apiService),
  ]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('jan3AuthProvider - build()', () {
    test('empty walletId returns unauthenticated without touching dependencies',
        () async {
      final container = makeContainer(
        tokenManager: FakeJan3AuthTokenManager(),
      );
      addTearDown(container.dispose);

      final state = await container.read(jan3AuthProvider('').future);

      expect(state, isA<Jan3UserUnauthenticated>());
    });

    test('no token and no stored profile returns unauthenticated', () async {
      final container = makeContainer(
        tokenManager: FakeJan3AuthTokenManager(walletId: kTestWalletId),
        walletState: WalletState(wallets: [makeWallet()]),
      );
      addTearDown(container.dispose);

      final state =
          await container.read(jan3AuthProvider(kTestWalletId).future);

      expect(state, isA<Jan3UserUnauthenticated>());
    });

    test('token exists and API succeeds returns authenticated', () async {
      final mockApi = MockJan3ApiService();
      when(() => mockApi.getUser())
          .thenAnswer((_) async => successResponse(kTestProfile));

      final container = makeContainer(
        tokenManager: FakeJan3AuthTokenManager(
          walletId: kTestWalletId,
          accessToken: 'access-token',
          storedToken: kTestAuthToken,
        ),
        walletState: WalletState(wallets: [makeWallet()]),
        apiService: mockApi,
      );
      addTearDown(container.dispose);

      final state =
          await container.read(jan3AuthProvider(kTestWalletId).future);

      expect(state, isA<Jan3UserAuthenticated>());
      expect((state as Jan3UserAuthenticated).profile, kTestProfile);
    });

    test('token exists but API fails returns unauthenticated', () async {
      final mockApi = MockJan3ApiService();
      when(() => mockApi.getUser()).thenAnswer((_) async => failureResponse());

      final container = makeContainer(
        tokenManager: FakeJan3AuthTokenManager(
          walletId: kTestWalletId,
          accessToken: 'access-token',
        ),
        walletState: WalletState(wallets: [makeWallet()]),
        apiService: mockApi,
      );
      addTearDown(container.dispose);

      final state =
          await container.read(jan3AuthProvider(kTestWalletId).future);

      expect(state, isA<Jan3UserUnauthenticated>());
    });

    test('no token but wallet has stored profile and authToken restores auth',
        () async {
      final spy = SpyStorage();

      final container = makeContainer(
        tokenManager: FakeJan3AuthTokenManager(
          walletId: kTestWalletId,
          storage: spy,
        ),
        walletState: WalletState(wallets: [
          makeWallet(profile: kTestProfile, authToken: kTestAuthToken),
        ]),
      );
      addTearDown(container.dispose);

      final state =
          await container.read(jan3AuthProvider(kTestWalletId).future);

      expect(state, isA<Jan3UserAuthenticated>());
      expect((state as Jan3UserAuthenticated).profile, kTestProfile);
      expect(spy.savedEntries, contains('jan3_auth_token_$kTestWalletId'));
    });
  });
}
