import 'package:aqua/features/depix/services/jan3_api_depix.dart';
import 'package:aqua/features/depix/utils/brl_cents.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/shared/pages/amount_entry/amount_entry_spec.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const AmountEntrySpec depixAmountEntrySpecFallback = AmountEntrySpec(
  fiat: FiatCurrency.brl,
  assetTicker: 'DePix',
  assetPerFiatUnit: 1.0,
  fixedFiatFee: 0.99,
);

AmountEntrySpec _specFromFeeBrlCents(int cents) => AmountEntrySpec(
      fiat: FiatCurrency.brl,
      assetTicker: 'DePix',
      assetPerFiatUnit: 1.0,
      fixedFiatFee: cents.asBrl,
    );

class DepixAmountEntrySpecNotifier
    extends AutoDisposeAsyncNotifier<AmountEntrySpec> {
  @override
  Future<AmountEntrySpec> build() async {
    try {
      final response = await ref.read(jan3ApiDepixProvider).getPixDepixFee();
      if (!response.isSuccessful || response.body == null) {
        return depixAmountEntrySpecFallback;
      }
      return _specFromFeeBrlCents(response.body!.pixDepixFeeBrlCents);
    } catch (_) {
      return depixAmountEntrySpecFallback;
    }
  }
}

final depixAmountEntrySpecProvider = AutoDisposeAsyncNotifierProvider<
    DepixAmountEntrySpecNotifier, AmountEntrySpec>(
  DepixAmountEntrySpecNotifier.new,
);
