import 'package:coin_cz/features/account/account.dart';
import 'package:coin_cz/features/private_integrations/debit_card/provider/provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final moonCardsProvider =
    AsyncNotifierProvider.autoDispose<MoonCardsNotifier, List<CardResponse>>(
        MoonCardsNotifier.new);

class MoonCardsNotifier extends AutoDisposeAsyncNotifier<List<CardResponse>>
    implements DebitCardSource {
  @override
  Future<List<CardResponse>> build() {
    // Listen to auth state changes and refresh cards
    ref.listen(jan3AuthProvider, (previous, next) {
      if (previous?.value != next.value) {
        _refreshCards();
      }
    });

    return _getDebitCards();
  }

  Future<void> _refreshCards() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _getDebitCards());
  }

  Future<List<CardResponse>> _getDebitCards() async {
    final api = await ref.read(jan3ApiServiceProvider.future);
    final response = await api.getCards();
    return response.body?.cards ?? [];
  }

  @override
  Future<void> createDebitCard() async {
    state = const AsyncValue.loading();
    final api = await ref.read(jan3ApiServiceProvider.future);
    await api.createCard(null);
    _refreshCards();
  }
}
