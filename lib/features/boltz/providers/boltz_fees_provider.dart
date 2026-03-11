import 'package:aqua/features/shared/shared.dart';
import 'package:boltz/boltz.dart';

// ANCHOR - Boltz Fees Provider
final boltzFeesProvider = AsyncNotifierProvider<BoltzFeesNotifier, Fees>(
  BoltzFeesNotifier.new,
);

class BoltzFeesNotifier extends AsyncNotifier<Fees> {
  @override
  Future<Fees> build() async {
    final boltzUrl = ref.read(boltzEnvConfigProvider).apiUrl;
    return await Fees.newInstance(boltzUrl: boltzUrl);
  }

  /// Refresh fees configuration
  void refresh() {
    ref.invalidateSelf();
  }
}
