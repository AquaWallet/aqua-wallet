import 'package:aqua/features/boltz/providers/boltz_api_url_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:boltz/boltz.dart';

// ANCHOR - Boltz Fees Provider (submarine vs reverse hosts)
final boltzFeesProvider =
    AsyncNotifierProvider.autoDispose.family<BoltzFeesNotifier, Fees, SwapType>(
  BoltzFeesNotifier.new,
);

class BoltzFeesNotifier extends AutoDisposeFamilyAsyncNotifier<Fees, SwapType> {
  @override
  Future<Fees> build(SwapType arg) async {
    final boltzUrl = await ref.watch(boltzApiUrlProvider(arg).future);
    return Fees.newInstance(boltzUrl: boltzUrl);
  }

  /// Refresh fees configuration
  void refresh() {
    ref.invalidateSelf();
  }
}
