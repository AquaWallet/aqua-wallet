import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/receive/providers/providers.dart';
import 'package:aqua/features/settings/exchange_rate/providers/conversion_currencies_provider.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class BoltzFeeWidget extends ConsumerWidget {
  final String? amountEntered;

  const BoltzFeeWidget({
    super.key,
    required this.amountEntered,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // fiat conversion setup
    final referenceCurrency = ref.read(prefsProvider).referenceCurrency;
    final fiatCurrency = ref.watch(amountCurrencyProvider);
    final fiatRates = ref.watch(fiatRatesProvider).asData?.value;
    final rate = fiatRates
        ?.firstWhere(
            (element) => element.code == (fiatCurrency ?? referenceCurrency))
        .rate;
    final isFiatToggled = ref.watch(amountCurrencyProvider) != null;

    // fee in sats
    final amountString = amountEntered != null && amountEntered!.isNotEmpty
        ? amountEntered!
        : "0";
    final amountEnteredDouble = double.parse(amountString).toInt();
    final amountFiatToSats =
        rate != null ? amountEnteredDouble / (rate / satsPerBtc) : null;
    final amountSats =
        isFiatToggled ? amountFiatToSats!.toInt() : amountEnteredDouble;
    final totalServiceFeeSats = BoltzFees.totalFeesForAmountReverse(amountSats);

    // fee in fiat
    final amountFiat = rate != null
        ? (totalServiceFeeSats / (satsPerBtc / rate)).toStringAsFixed(2)
        : '';

    return Text(
        "${context.loc.boltzTotalFees}: ${totalServiceFeeSats.ceil()} sats (${fiatCurrency ?? referenceCurrency} $amountFiat)");
  }
}
