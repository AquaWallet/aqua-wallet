import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
import 'package:aqua/features/settings/shared/widgets/settings_selection_list.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/components/top_app_bar/top_app_bar.dart';
import 'package:ui_components/ui_components.dart';

class PriceSourceScreen extends HookConsumerWidget {
  const PriceSourceScreen({
    super.key,
    required this.exchangeRate,
  });

  static const routeName = '/priceSourceScreen';

  final ExchangeRate exchangeRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSources = ref.watch(
      exchangeRatesProvider.select(
        (p) => p.sourcesForCurrentCurrency(exchangeRate.currency.name),
      ),
    );
    final currentSource = ref.watch(gdkSettingsProvider);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
        title: context.loc
            .currencyPriceSource(exchangeRate.currency.name.toUpperCase()),
      ),
      body: Column(
        children: [
          SettingsSelectionList(
            showSearch: false,
            items: availableSources
                .mapIndexed(
                  (index, item) => SettingsItem.create(
                    item,
                    name: item.displayName,
                    index: index,
                    length: 10,
                  ),
                )
                .toList(),
            itemBuilder: (context, item) {
              final source = item.object as ExchangeRateSource;
              final currentPricing = currentSource.asData?.value.pricing;
              // Only show selection if this screen's currency is the active currency
              final isActiveCurrency =
                  currentPricing?.currency?.toUpperCase() ==
                      exchangeRate.currency.value.toUpperCase();

              return SettingsListSelectionItem(
                title: source.displayName,
                isRadioButton: true,
                radioGroupValue:
                    isActiveCurrency ? currentPricing?.exchange : null,
                radioValue: source.value,
                onPressed: () {
                  ref.read(exchangeRatesProvider).setReferenceCurrency(
                        ExchangeRate(
                          exchangeRate.currency,
                          source,
                        ),
                      );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
