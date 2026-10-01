import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:boltz/boltz.dart';

// Cached submarine fees and limits. The swap provider package performs a
// fresh HTTP request on every `submarine()` call, so consumers should watch
// this provider instead of calling it directly.
final boltzSubmarineFeesProvider = AsyncNotifierProvider.autoDispose<
    BoltzSubmarineFeesNotifier, SubmarineFeesAndLimits>(
  BoltzSubmarineFeesNotifier.new,
);

class BoltzSubmarineFeesNotifier
    extends AutoDisposeAsyncNotifier<SubmarineFeesAndLimits> {
  @override
  Future<SubmarineFeesAndLimits> build() => requireBoltzService(() async {
        final fees =
            await ref.watch(boltzFeesProvider(SwapType.submarine).future);
        return fees.submarine();
      });
}
