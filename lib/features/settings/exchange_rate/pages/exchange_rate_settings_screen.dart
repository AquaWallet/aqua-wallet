import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

class ExchangeRateSettingsScreen extends HookConsumerWidget {
  static const routeName = '/exchangeRateSettingsScreen';

  const ExchangeRateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
        .watch(exchangeRatesProvider.select((p) => p.availableExchangeRates));
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        title: AppLocalizations.of(context)!.refExRateSettingsScreenTitle,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: currentRate.displayName,
          items: items
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.name, index: index, length: items.length))
              .toList(),
          itemBuilder: (context, item) {
            final currency = item.object as ExchangeRate;
            return SettingsListSelectionItem(
              content: Text(currency.displayName),
              position: item.position,
              onPressed: () => ref
                  .read(exchangeRatesProvider)
                  .setReferenceCurrency(currency),
            );
          },
        ),
      ),
    );
  }
}
