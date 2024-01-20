import 'package:aqua/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

final envSwitchProvider =
    Provider.autoDispose<EnvSwitchProvider>((ref) => EnvSwitchProvider(ref));

/// Allows a way for the user to tap an element 10 times to switch environments
class EnvSwitchProvider {
  final AutoDisposeProviderRef ref;

  EnvSwitchProvider(this.ref);

  int _envCounter = 0;

  final _tapEnvSwitchSubject = PublishSubject<Object>();
  late final Stream<Object> _tapEnvSwitchStream = _tapEnvSwitchSubject.map((_) {
    return _envCounter++;
  }).switchMap((counter) {
    if (counter >= 9) {
      _envCounter = 0;
      return Stream<Object>.value(Object());
    }

    return const Stream<Object>.empty();
  }).shareReplay(maxSize: 1);

  void setTapEnv() {
    _tapEnvSwitchSubject.add(Object());
  }
}

final _tapEnvSwitchStreamProvider =
    StreamProvider.autoDispose<Object>((ref) async* {
  yield* ref.watch(envSwitchProvider)._tapEnvSwitchStream;
});

final tapEnvSwitchProvider = Provider.autoDispose<Object?>((ref) {
  return ref.watch(_tapEnvSwitchStreamProvider).asData?.value;
});
