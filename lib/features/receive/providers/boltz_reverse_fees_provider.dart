import 'package:aqua/features/boltz/providers/boltz_fees_provider.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final boltzReverseFeesProvider = AsyncNotifierProvider.autoDispose<
    BoltzReverseFeesNotifier, ReverseFeesAndLimits>(
  BoltzReverseFeesNotifier.new,
);

class BoltzReverseFeesNotifier
    extends AutoDisposeAsyncNotifier<ReverseFeesAndLimits> {
  @override
  Future<ReverseFeesAndLimits> build() async {
    final fees = await ref.read(boltzFeesProvider.future);
    return await fees.reverse();
  }
}
