import 'dart:async';

import 'package:aqua/features/wallet/models/wallet_state.dart';
import 'package:aqua/features/wallet/providers/stored_wallets_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockStoredWalletsNotifier extends AsyncNotifier<WalletState>
    with Mock
    implements StoredWalletsNotifier {
  final WalletState? _initialState;

  MockStoredWalletsNotifier({WalletState? initialState})
      : _initialState = initialState;

  @override
  FutureOr<WalletState> build() async =>
      _initialState ?? const WalletState(wallets: []);

  @override
  Future<void> addWallet({
    String? mnemonic,
    required String name,
    String? description,
    dynamic samRockAppLink,
    WalletOperationType? operationType,
  }) async {}
}
