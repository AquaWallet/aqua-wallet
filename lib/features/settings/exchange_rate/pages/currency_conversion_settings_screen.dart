import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
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
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(left: 18.w, right: 12.w),
                  child: SvgPicture.asset(
                    Svgs.search,
                    width: 16.r,
                    height: 16.r,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onBackground,
                        BlendMode.srcIn),
                  ),
                ),
                border: InputBorder.none,
              ),
            ),
            Expanded(
              child: ListView.separated(
                  padding: EdgeInsets.only(left: 28.w, right: 28.w, top: 20.h),
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
