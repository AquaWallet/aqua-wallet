import 'package:aqua/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

final addNoteProvider =
    Provider.autoDispose<AddNoteProvider>((ref) => AddNoteProvider(ref));

class AddNoteProvider {
  AddNoteProvider(this._ref) {
    _ref.onDispose(() {
      _textSubject.close();
      _saveSubject.close();
      _popSubject.close();
    });
  }

  final AutoDisposeProviderRef _ref;

  final BehaviorSubject<String> _textSubject = BehaviorSubject.seeded('');
  void updateText(String text) {
    _textSubject.add(text);
  }

  final PublishSubject<void> _saveSubject = PublishSubject();
  void save() {
    _saveSubject.add(null);
  }

  final PublishSubject<void> _popSubject = PublishSubject();
  void pop() {
    _popSubject.add(null);
  }

  Stream<String?> _popStream() => Rx.merge([
        _saveSubject
            .asyncMap((_) => _textSubject.first)
            .map((text) => text.isNotEmpty ? text : null),
        _popSubject.map((_) => null),
      ]);
}

final _addNotePopStreamProvider =
    StreamProvider.autoDispose<String?>((ref) async* {
  yield* ref.watch(addNoteProvider)._popStream();
});

final addNotePopProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(_addNotePopStreamProvider).asData?.value;
});
