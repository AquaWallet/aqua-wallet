import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ExchangeRateSettingsScreen extends HookConsumerWidget {
  static const routeName = '/exchangeRateSettingsScreen';

  const ExchangeRateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(exchangeRatesProvider.select((p) => p.availableCurrencies));
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    final displayUnits =
        ref.watch(displayUnitsProvider.select((p) => p.supportedDisplayUnits));
    final currentDisplayUnit =
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));

    final currencyFilter = useMemoized(
      () => (SettingsItem item, String query) {
        if (query.isEmpty) return 0;
        final exchangeRate = item.object as ExchangeRate;
        final currencyName = item.name.toLowerCase();
        final currencyCode = exchangeRate.currency.value.toLowerCase();
        final queryLower = query.toLowerCase();
        final startsWith = currencyName.startsWith(queryLower) ||
            currencyCode.startsWith(queryLower);
        final contains = currencyName.contains(queryLower) ||
            currencyCode.contains(queryLower);
        if (startsWith) return 0;
        if (contains) return 1;
        return null;
      },
      [],
    );

    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        showBackButton: true,
        colors: context.aquaColors,
        title: context.loc.unitAndCurrencySettingsTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Padding to account for the app bar
            const AppBarPadding(),
            AquaText.body1SemiBold(
              text: context.loc.displayUnits,
            ),
            const SizedBox(height: 16),
            SettingsSelectionList(
              padding: EdgeInsets.zero,
              includeAppBarPadding: false,
              items: displayUnits
                  .mapIndexed(
                    (index, item) => SettingsItem.create(
                      item,
                      name: item.value,
                      index: index,
                      length: displayUnits.length,
                    ),
                  )
                  .toList(),
              itemBuilder: (context, item) {
                return SettingsListSelectionItem(
                  title: item.name,
                  isRadioButton: true,
                  radioValue: item.name,
                  radioGroupValue: currentDisplayUnit.value,
                  onPressed: () => ref
                      .read(displayUnitsProvider)
                      .setCurrentDisplayUnit(item.name),
                );
              },
            ),
            const SizedBox(height: 28),
            AquaText.body1SemiBold(
              text: context.loc.referenceCurrency,
            ),
            const SizedBox(height: 16),
            if (items.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: AquaText.body1(
                  text: context.loc.failedToFetchReferenceRates,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              SettingsSelectionList(
                showSearch: true,
                includeAppBarPadding: false,
                padding: EdgeInsets.zero,
                items: items
                    .mapIndexed(
                      (index, item) => SettingsItem.create(
                        item,
                        name: currencyLabelLookup(item.currency, context),
                        index: index,
                        length: items.length,
                      ),
                    )
                    .toList(),
                filter: currencyFilter,
                itemBuilder: (context, item) {
                  final exchangeRate = item.object as ExchangeRate;
                  final availableSources = ref.read(
                    exchangeRatesProvider.select(
                      (p) => p.sourcesForCurrentCurrency(
                        exchangeRate.currency.name,
                      ),
                    ),
                  );
                  return SettingsListSelectionItem<ExchangeRate>(
                    title: exchangeRate.displayName(context),
                    subTitle: availableSources.length > 1
                        ? context.loc.choosePriceSource
                        : exchangeRate.source.displayName,
                    isRadioButton: !(availableSources.length > 1),
                    radioValue: exchangeRate,
                    radioGroupValue: currentRate,
                    icon: CountryFlag(
                      svgAsset: exchangeRate.currency.format.flagSvg,
                      size: 20,
                    ),
                    iconTrailing: availableSources.length > 1
                        ? AquaIcon.chevronForward(
                            size: 18,
                            color: context.aquaColors.textSecondary,
                          )
                        : null,
                    onPressed: () {
                      if (availableSources.length > 1) {
                        context.push(
                          PriceSourceScreen.routeName,
                          extra: exchangeRate,
                        );
                      } else {
                        ref
                            .read(exchangeRatesProvider)
                            .setReferenceCurrency(exchangeRate);
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
