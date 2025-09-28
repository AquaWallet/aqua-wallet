import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/shared/shared.dart';

final jan3MoonStatsProvider = AsyncNotifierProvider.autoDispose<
    Jan3MoonStatsNotifier, MoonCardStatsResponse?>(Jan3MoonStatsNotifier.new);

class Jan3MoonStatsNotifier
    extends AutoDisposeAsyncNotifier<MoonCardStatsResponse?> {
  @override
  Future<MoonCardStatsResponse?> build() async {
    return _getMoonStats();
  }

  Future<MoonCardStatsResponse?> _getMoonStats() async {
    final api = await ref.read(jan3ApiServiceProvider.future);
    try {
      final response = await api.getUser();

      if (response.isSuccessful && response.body != null) {
        return response.body!.moonStats;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
