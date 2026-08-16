import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:boltz/boltz.dart';

final boltzReverseFeesProvider = AsyncNotifierProvider.autoDispose<
    BoltzReverseFeesNotifier, ReverseFeesAndLimits>(
  BoltzReverseFeesNotifier.new,
);

class BoltzReverseFeesNotifier
    extends AutoDisposeAsyncNotifier<ReverseFeesAndLimits> {
  @override
  Future<ReverseFeesAndLimits> build() => requireBoltzService(() async {
        final fees =
            await ref.watch(boltzFeesProvider(SwapType.reverse).future);
        return fees.reverse();
      });
}
