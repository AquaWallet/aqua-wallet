import 'package:coin_cz/data/provider/fiat_provider.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/receive/providers/providers.dart';
import 'package:coin_cz/features/settings/exchange_rate/providers/conversion_currencies_provider.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/settings/shared/providers/providers.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:decimal/decimal.dart';

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
        ?.firstWhereOrNull(
            (element) => element.code == (fiatCurrency ?? referenceCurrency))
        ?.rate;
    final isFiatToggled = ref.watch(amountCurrencyProvider) != null;

    // fee in sats
    final amountString = amountEntered != null && amountEntered!.isNotEmpty
        ? amountEntered!
        : "0";
    final amountEnteredDouble = double.parse(amountString).toInt();
    final amountFiatToSats = rate != null
        ? amountEnteredDouble / (rate / satsPerBtc)
        : ref
                .watch(fiatToSatsAsIntProvider((
                  Asset.btc(),
                  amountEnteredDouble.toDecimal()
                ))) // We are using asset.btc here because the rates are per btc
                .asData
                ?.value ??
            0;
    final amountSats =
        isFiatToggled ? amountFiatToSats.toInt() : amountEnteredDouble;
    final totalServiceFeeSats = BoltzFees.totalFeesForAmountReverse(amountSats);

    // fee in fiat
    final amountFiat = rate != null
        ? '${fiatCurrency ?? referenceCurrency} ${(totalServiceFeeSats / (satsPerBtc / rate)).toStringAsFixed(2)}'
        : ref
            .watch(satsToFiatDisplayWithSymbolProvider(totalServiceFeeSats))
            .asData
            ?.value;

    return Text(
        "${context.loc.boltzTotalFees}: ${totalServiceFeeSats.ceil()} sats ($amountFiat)");
  }
}
