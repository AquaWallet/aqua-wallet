import 'package:coin_cz/data/provider/aqua_provider.dart';
import 'package:coin_cz/data/provider/initialize_app_provider.dart';
import 'package:coin_cz/features/onboarding/onboarding.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

final _entryPointProvider =
    Provider<EntryPointProvider>((ref) => EntryPointProvider(ref));

class EntryPointProvider {
  EntryPointProvider(this._ref);

  final ProviderRef _ref;

  late final Stream<EntryPoint> _entryPointStream = _ref
      .read(initAppProvider)
      .initAppStream
      .switchMap((value) => value.maybeWhen(
            data: (_) => _ref.read(aquaProvider).authStream.map((value) =>
                value.when(
                    data: (_) => const EntryPoint.home(),
                    loading: () => const EntryPoint.loading(),
                    error: (error, _) =>
                        (error is AquaProviderBiometricFailureException)
                            ? EntryPoint.error(error: error)
                            : const EntryPoint.welcome())),
            loading: () => Stream.value(const EntryPoint.loading()),
            orElse: () => Stream.value(const EntryPoint.error()),
          ))
      .shareReplay(maxSize: 1);
}

final _entryPointStreamProvider = StreamProvider<EntryPoint>((ref) async* {
  yield* ref.watch(_entryPointProvider)._entryPointStream;
});

final entryPointProvider = Provider<EntryPoint?>((ref) {
  return ref.watch(_entryPointStreamProvider).asData?.value;
});
