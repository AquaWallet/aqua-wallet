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

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.refExRateSettingsScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
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
      ),
    );
  }
}
