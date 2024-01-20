import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

//TODO - Remove RxDart dependency

const kMinWordLength = 3;

final walletRestoreItemProvider = Provider.family
    .autoDispose<WalletRestoreItemProvider, int>(
        (ref, index) => WalletRestoreItemProvider(ref));

class WalletRestoreItemProvider {
  WalletRestoreItemProvider(this.ref) {
    ref.onDispose(() {
      _updateTextSubject.close();
      _selectOptionSubject.close();
    });
  }
  final AutoDisposeProviderRef ref;
  final BehaviorSubject<String> _updateTextSubject = BehaviorSubject();
  Stream<String> updateTextStream() => _updateTextSubject.map((text) => text);

  /// This stream determines if the user entered text matches one of the bip39
  /// words in `optionsStream`
  /// - Note: Only fires when the user enters [kMinWordLength] or more
  /// characters, doesn't work for 3 letter words
  late final Stream<String?> _symbolsThresholdStream = _updateTextSubject
      .switchMap<String>((text) => text.length >= kMinWordLength
          ? Stream.value(text)
          : const Stream.empty())
      .map((text) => text.toLowerCase())
      .asyncMap((text) => ref
          .read(walletOptionsProvider)
          .optionsStream
          .switchMap<List<String>>((value) => value.asData?.value != null
              ? Stream.value(value.asData!.value)
              : const Stream.empty())
          .first
          .then((options) => options.where((op) => op.startsWith(text))))
      .switchMap((options) => options.length == 1
          ? Stream.value(options.first)
          : const Stream.empty());

  /// This stream fires when the user manually selects an option from the autocomplete list
  final PublishSubject<String> _selectOptionSubject = PublishSubject();

  /// This stream get the value from either the automatic `_fourSymbolsThresholdStream` or user manual `_selectOptionSubject`
  late final Stream<(String?, int)?> fieldValueStream =
      Rx.merge([_symbolsThresholdStream, _selectOptionSubject])
          .startWith(null)
          // Sending the string alone makes the ProviderListener ignore the
          // value if the user tries to re-enter the same term as the one they
          // just removed. Sending a Tuple is a workaround to ensure it is a
          // unique object instance every time.
          .map((value) => (value, DateTime.now().millisecond))
          .shareReplay(maxSize: 1);

  void update(String text) {
    _updateTextSubject.add(text);
  }

  void select(String text) {
    _selectOptionSubject.add(text);
  }

  List<String> _suggestions() {
    final optionsStream = ref.read(walletOptionsProvider).optionsStream;
    return optionsStream.values.last.asData?.value ?? [];
  }

  Iterable<String> options(String text) {
    if (text.isEmpty) {
      return [];
    }
    final lowercasedText = text.toLowerCase();
    return _suggestions().where((String option) {
      return option.startsWith(lowercasedText);
    });
  }

  bool shouldClear(String text) {
    if (text.isEmpty) {
      return false;
    }
    return !_suggestions().contains(text);
  }
}

final _fieldValueStreamProvider = StreamProvider.family
    .autoDispose<(String?, int)?, int>((ref, index) async* {
  final fieldValueStream =
      ref.watch(walletRestoreItemProvider(index)).fieldValueStream;

  yield* fieldValueStream;
});

final fieldValueStreamProvider =
    Provider.family.autoDispose<(String?, int)?, int>((ref, index) {
  return ref.watch(_fieldValueStreamProvider(index)).asData?.value;
});
