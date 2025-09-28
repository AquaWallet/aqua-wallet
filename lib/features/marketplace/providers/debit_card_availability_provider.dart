import 'package:aqua/features/account/providers/jan3_moon_stats_provider.dart';
import 'package:aqua/features/private_integrations/debit_card/constants/constants.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

final debitCardAvailabilityProvider =
    AsyncNotifierProvider.autoDispose<DebitCardAvailabilityNotifier, bool>(
        DebitCardAvailabilityNotifier.new);

class DebitCardAvailabilityNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final currentRegion = ref.watch(regionsProvider).currentRegion;

    if (currentRegion == null) {
      return false;
    }

    // First check if region is blocked
    if (dolphinCardRestrictedIsoCodes.contains(currentRegion.iso)) {
      // If region is blocked, check if user has at least one card
      final moonStats = await ref.read(jan3MoonStatsProvider.future);

      if (moonStats == null) {
        return false;
      }

      final cardCount = moonStats.cardsCount ?? 0;

      if (cardCount == 0) {
        return false;
      }
    }

    return true;
  }
}
