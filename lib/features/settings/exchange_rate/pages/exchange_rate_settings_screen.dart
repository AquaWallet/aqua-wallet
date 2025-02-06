import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class ExchangeRateSettingsScreen extends HookConsumerWidget {
  static const routeName = '/exchangeRateSettingsScreen';

  const ExchangeRateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(exchangeRatesProvider.select((p) => p.availableCurrencies));
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    final availableSources = ref.watch(
        exchangeRatesProvider.select((p) => p.sourcesForCurrentCurrency));
    final currentSource = ref.watch(gdkSettingsProvider);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.refExRateSettingsScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  context.loc.refExRateSettingsScreenSourceLabel(
                      currentRate.currency.value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SettingsSelectionList(
                showSearch: false,
                label: currentSource.asData?.value.pricing?.exchange,
                items: availableSources
                    .mapIndexed((index, item) => SettingsItem.create(item,
                        name: item.value, index: index, length: items.length))
                    .toList(),
                itemBuilder: (context, item) {
                  final source = item.object as ExchangeRateSource;
                  return SettingsListSelectionItem(
                    content: Text(source.value),
                    position: item.position,
                    onPressed: () => ref
                        .read(exchangeRatesProvider)
                        .setReferenceCurrency(
                            ExchangeRate(currentRate.currency, source)),
                  );
                },
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  context.loc.refExRateSettingsScreenCurrencyLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SettingsSelectionList(
                showSearch: false,
                label: currentRate.displayName(context),
                items: items
                    .mapIndexed((index, item) => SettingsItem.create(item,
                        name: currencyLabelLookup(item.currency, context),
                        index: index,
                        length: items.length))
                    .toList(),
                itemBuilder: (context, item) {
                  final currency = item.object as ExchangeRate;
                  return SettingsListSelectionItem(
                    content: Text(currency.displayName(context)),
                    position: item.position,
                    onPressed: () => ref
                        .read(exchangeRatesProvider)
                        .setReferenceCurrency(currency),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
