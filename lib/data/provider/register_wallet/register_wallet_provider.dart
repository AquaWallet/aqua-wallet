import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:rxdart/rxdart.dart';

final registerWalletProvider = Provider.autoDispose<_RegisterWalletProvider>(
    (ref) => _RegisterWalletProvider(ref));

class _RegisterWalletProvider {
  _RegisterWalletProvider(this._ref) {
    _ref.onDispose(() {
      _registerSubject.close();
    });
  }

  final AutoDisposeProviderRef _ref;

  final PublishSubject<String?> _registerSubject = PublishSubject();
  void register({String? walletName}) {
    _registerSubject.add(walletName);
  }

  late final Stream<AsyncValue<void>> _registrationProcessingStream =
      _registerSubject
          .switchMap((walletName) => Rx.combineLatest2(
                Rx.timer(null, const Duration(seconds: 2)),
                Stream.value(walletName).asyncMap((walletName) async {
                  // 1. Perform full cleanup before creating new wallet
                  await _ref
                      .read(aquaConnectionProvider.notifier)
                      .fullCleanup();

                  // 2. Generate mnemonic
                  final mnemonic =
                      await _ref.read(liquidProvider).generateMnemonic12();
                  if (mnemonic == null) {
                    throw RegisterWalletInvalidMnemonicException();
                  }
                  return (mnemonic: mnemonic.join(' '), walletName: walletName);
                }).asyncMap((data) async {
                  // 3. Add wallet to stored wallets (this will handle connection internally)
                  if (data.walletName != null) {
                    await _ref.read(storedWalletsProvider.notifier).addWallet(
                          mnemonic: data.mnemonic,
                          name: data.walletName!,
                          operationType: WalletOperationType.create,
                        );
                  }

                  return null;
                }),
                (a, b) => const AsyncValue.data(null),
              ).startWith(const AsyncValue.loading()).onErrorReturnWith(
                  (error, stackTrace) => AsyncValue.error(error, stackTrace)))
          .shareReplay(maxSize: 1);
}

final _registerWalletProcessingStreamProvider =
    StreamProvider.autoDispose<AsyncValue<void>>((ref) async* {
  yield* ref.watch(registerWalletProvider)._registrationProcessingStream;
});

final registerWalletProcessingProvider =
    Provider.autoDispose<AsyncValue<void>?>((ref) {
  return ref.watch(_registerWalletProcessingStreamProvider).asData?.value;
});

class RegisterWalletInvalidMnemonicException implements Exception {}
