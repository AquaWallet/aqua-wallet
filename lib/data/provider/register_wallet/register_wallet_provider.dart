import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';

final registerWalletProvider = Provider.autoDispose<_RegisterWalletProvider>(
    (ref) => _RegisterWalletProvider(ref));

class _RegisterWalletProvider {
  _RegisterWalletProvider(this._ref) {
    _ref.onDispose(() {
      _registerSubject.close();
    });
  }

  final AutoDisposeProviderRef _ref;

  final PublishSubject<void> _registerSubject = PublishSubject();
  void register() {
    _registerSubject.add(null);
  }

  late final Stream<AsyncValue<void>> _registrationProcessingStream =
      _registerSubject
          .switchMap((_) => Rx.combineLatest2(
                Rx.timer(null, const Duration(seconds: 12)),
                Stream.value(_)
                    .asyncMap((_) async {
                      final mnemonic =
                          await _ref.read(liquidProvider).generateMnemonic12();
                      if (mnemonic == null) {
                        throw RegisterWalletInvalidMnemonicException();
                      }
                      return mnemonic;
                    })
                    .map((mnemonic) => mnemonic.join(' '))
                    .asyncMap((mnemonic) => _ref
                        .read(secureStorageProvider)
                        .save(key: StorageKeys.mnemonic, value: mnemonic)),
                (a, b) => AsyncValue.data(_),
              )
                  .doOnData((_) =>
                      _ref.read(aquaConnectionProvider.notifier).connect())
                  .startWith(const AsyncValue.loading())
                  .onErrorReturnWith((error, stackTrace) =>
                      AsyncValue.error(error, stackTrace)))
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
