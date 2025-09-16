import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConversionCurrenciesSettingsScreen extends HookConsumerWidget {
  static const routeName = '/conversionCurrenciesSettingsScreen';

  const ConversionCurrenciesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiatRates = ref.watch(fiatRatesProvider);
    final availableCurrencies = ref.watch(
        conversionCurrenciesProvider.select((p) => p.availableCurrencies));

    final query = useState('');
    final listItems = useMemoized(
      () => availableCurrencies
          .where((item) =>
              query.value == '' ||
              item.name.toLowerCase().contains(query.value.toLowerCase()) ||
              item.code.toLowerCase().contains(query.value.toLowerCase()))
          .toList(),
      [query.value],
    );

    final enabledCurrencies = ref
        .watch(conversionCurrenciesProvider.select((p) => p.enabledCurrencies));
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.conversionCurrenciesScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SafeArea(
          child: fiatRates.when(
        data: (data) => Column(
          children: [
            TextField(
              onChanged: (value) => query.value = value,
              decoration: InputDecoration(
                hintText: context.loc.conversionCurrenciesSearchHint,
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colors.onBackground,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 18.0, right: 12.0),
                  child: SvgPicture.asset(
                    Svgs.search,
                    width: 16.0,
                    height: 16.0,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colors.onBackground, BlendMode.srcIn),
                  ),
                ),
                border: InputBorder.none,
              ),
            ),
            Expanded(
              child: ListView.separated(
                  padding:
                      const EdgeInsets.only(left: 28.0, right: 28.0, top: 20.0),
                  separatorBuilder: (context, index) => const Divider(),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final currency = listItems[index];
                    return SwitchListTile(
                      value: enabledCurrencies.contains(currency.code),
                      title: Text(currency.name),
                      secondary: Text(currency.code),
                      onChanged: (bool value) {
                        if (value == true) {
                          ref
                              .read(conversionCurrenciesProvider)
                              .addCurrency(currency.code);
                          return;
                        }

                        ref
                            .read(conversionCurrenciesProvider)
                            .removeCurrency(currency.code);
                      },
                    );
                  }),
            ),
          ],
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      )),
    );
  }
}
