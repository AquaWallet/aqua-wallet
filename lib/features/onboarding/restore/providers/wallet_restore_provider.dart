import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

//TODO - Remove RxDart dependency

const kMnemonicLength = 12;

final walletRestoreProcessingProvider =
    Provider.autoDispose(WalletRestoreProcessingProvider.new);

class WalletRestoreProcessingProvider {
  WalletRestoreProcessingProvider(this.ref) {
    ref.onDispose(() {
      _restoreSubject.close();
    });
  }

  final AutoDisposeProviderRef ref;
  final PublishSubject<void> _restoreSubject = PublishSubject();

  void restore() {
    _restoreSubject.add(null);
  }

  /// This stream validates the entered words and saves them to secure storage
  late final Stream<AsyncValue<void>> _restoreProcessingStream = _restoreSubject
      .switchMap((_) => Rx.combineLatest2(
            Rx.timer(null, const Duration(seconds: 12)),
            Stream.value(_)
                .asyncMap((_) => Rx.combineLatestList(
                        List.generate(kMnemonicLength, (index) {
                      return ref
                          .read(walletRestoreItemProvider(index))
                          .fieldValueStream
                          .switchMap((tuple) {
                        // check if we have a value from fieldValueStream, which is either the auto-completed value from `_fourSymbolsThresholdStream` or the user manually selected `_selectOptionSubject`
                        if (tuple?.$1 != null) {
                          return Stream.value(tuple);
                          // else just grab the value in the field
                        } else {
                          return ref
                              .read(walletRestoreItemProvider(index))
                              .updateTextStream()
                              .startWith('')
                              .map((str) => (str, DateTime.now().millisecond));
                        }
                      });
                    })).first)
                .map((mnemonic) =>
                    mnemonic.map((s) => s?.$1).whereType<String>().toList())
                .asyncMap((mnemonic) async {
                  final isValid =
                      await ref.read(liquidProvider).validateMnemonic(mnemonic);
                  if (isValid) {
                    ref.read(backupReminderProvider).setIsWalletBackedUp(true);
                  }
                  if (!isValid) {
                    throw WalletRestoreInvalidMnemonicException();
                  }
                  return mnemonic;
                })
                .map((mnemonic) => mnemonic.join(' '))
                .asyncMap((mnemonic) => ref
                    .read(secureStorageProvider)
                    .save(key: StorageKeys.mnemonic, value: mnemonic)),
            (a, b) => b,
          )
              .doOnData((_) => ref.read(aquaProvider).authorize())
              .map((result) => AsyncValue.data(result))
              .startWith(const AsyncValue.loading())
              .onErrorReturnWith(
                  (error, stacktrace) => AsyncValue.error(error, stacktrace)))
      .shareReplay(maxSize: 1);
}

final _walletRestoreStreamProvider =
    StreamProvider.autoDispose<AsyncValue<void>>((ref) async* {
  final restoreProcessingStream =
      ref.watch(walletRestoreProcessingProvider)._restoreProcessingStream;
  yield* restoreProcessingStream;
});

final walletRestoreResultProvider =
    Provider.autoDispose<AsyncValue<void>?>((ref) {
  return ref.watch(_walletRestoreStreamProvider).asData?.value;
});
