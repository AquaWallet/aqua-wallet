import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rxdart/rxdart.dart';

//TODO - Remove RxDart dependency

final walletOptionsProvider = Provider.autoDispose(WalletOptionsProvider.new);

class WalletOptionsProvider {
  WalletOptionsProvider(this.ref) {
    ref.onDispose(() {
      _reloadSubject.close();
    });
  }
  final AutoDisposeProviderRef ref;
  final PublishSubject<void> _reloadSubject = PublishSubject();

  /// This stream loads the bip39 wordlist from assets/wordlist.txt
  late final ReplayStream<AsyncValue<List<String>>> optionsStream =
      _reloadSubject
          .startWith(null)
          .switchMap((_) => loadList()
              .asStream()
              .map((list) => AsyncValue.data(list))
              .startWith(const AsyncValue.loading())
              .onErrorReturnWith(
                  (error, stackTrace) => AsyncValue.error(error, stackTrace)))
          .shareReplay(maxSize: 1);
  Future<List<String>> loadList() async {
    try {
      final string = await rootBundle.loadString('assets/wordlist.txt');
      return string.split('\n');
    } catch (e) {
      throw WalletRestoreInvalidOptionsException();
    }
  }

  void reload() {
    _reloadSubject.add(null);
  }
}

final _walletOptionsStreamProvider =
    StreamProvider.autoDispose<AsyncValue<List<String>>>((ref) async* {
  final restoreProcessingStream =
      ref.watch(walletOptionsProvider).optionsStream;
  yield* restoreProcessingStream;
});
final walletOptionsValueProvider =
    Provider.autoDispose<AsyncValue<List<String>>?>((ref) {
  return ref.watch(_walletOptionsStreamProvider).asData?.value;
});
