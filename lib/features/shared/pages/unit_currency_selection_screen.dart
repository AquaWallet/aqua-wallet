import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class UnitCurrencySelectionArguments {
  final Asset asset;
  final bool allowUnitSelection;
  final ExchangeRate currentRate;
  final AquaAssetInputUnit currentUnit;
  final bool popOnSelect;

  const UnitCurrencySelectionArguments({
    required this.asset,
    required this.allowUnitSelection,
    required this.currentRate,
    required this.currentUnit,
    this.popOnSelect = true,
  });

  UnitCurrencySelectionArguments copyWith({
    ExchangeRate? currentRate,
    AquaAssetInputUnit? currentUnit,
  }) {
    return UnitCurrencySelectionArguments(
      asset: asset,
      allowUnitSelection: allowUnitSelection,
      currentRate: currentRate ?? this.currentRate,
      currentUnit: currentUnit ?? this.currentUnit,
      popOnSelect: popOnSelect,
    );
  }
}

// A generic screen for selecting the unit and currency for an asset.
// It is used in the receive and send screens.
class UnitCurrencySelectionScreen extends HookConsumerWidget {
  static const routeName = '/unitCurrencySelectionScreen';

  const UnitCurrencySelectionScreen({
    super.key,
    required this.args,
  });

  final UnitCurrencySelectionArguments args;

  bool get popOnSelect => args.popOnSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const displayUnits = AquaAssetInputUnit.values;
    final currentRate = useState(args.currentRate);
    final currentUnit = useState(args.currentUnit);
    final currencies =
        ref.watch(exchangeRatesProvider.select((p) => p.availableCurrencies));

    final popWithResult = useCallback(() {
      final result = args.copyWith(
        currentRate: currentRate.value,
        currentUnit: currentUnit.value,
      );
      context.pop(result);
    }, [currentRate.value, currentUnit.value]);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // If GoRouter already handled the pop, do nothing.
        // Otherwise, manually pop with the result.
        if (!didPop) {
          popWithResult();
        }
      },
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          title: context.loc.unitAndCurrencySettingsTitle,
          colors: context.aquaColors,
          onBackPressed: popWithResult,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (args.allowUnitSelection) ...[
                  //ANCHOR - Display Unit Label
                  AquaText.body1SemiBold(
                    text: context.loc.displayUnits,
                  ),
                  const SizedBox(height: 16),
                  //ANCHOR - Display Unit List
                  SettingsSelectionList(
                    padding: EdgeInsets.zero,
                    items: displayUnits
                        .mapIndexed(
                          (index, e) => SettingsItem.create(
                            e,
                            name: e == AquaAssetInputUnit.crypto
                                ? args.asset.ticker
                                : args.asset.getDisplayTicker(
                                    SupportedDisplayUnits.fromAssetInputUnit(e),
                                  ),
                            index: index,
                            length: displayUnits.length,
                          ),
                        )
                        .toList(),
                    itemBuilder: (context, item) => SettingsListSelectionItem(
                      title: item.name,
                      isRadioButton: true,
                      radioValue: item.object,
                      radioGroupValue: currentUnit.value,
                      onPressed: () async {
                        currentUnit.value = item.object as AquaAssetInputUnit;
                        if (popOnSelect) {
                          // delay 100 milliseconds
                          await Future.delayed(
                              const Duration(milliseconds: 150));
                          popWithResult();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                //ANCHOR - Reference Currency Label
                AquaText.body1SemiBold(
                  text: context.loc.referenceCurrency,
                ),
                const SizedBox(height: 16),
                //ANCHOR - Reference Currency List
                SettingsSelectionList(
                    showSearch: true,
                    padding: EdgeInsets.zero,
                    items: currencies
                        .mapIndexed(
                          (index, item) => SettingsItem.create(
                            item,
                            name: currencyLabelLookup(item.currency, context),
                            index: index,
                            length: currencies.length,
                          ),
                        )
                        .toList(),
                    itemBuilder: (context, item) {
                      final exchangeRate = item.object as ExchangeRate;
                      return SettingsListSelectionItem(
                        title: exchangeRate.displayName(context),
                        isRadioButton: true,
                        radioValue: exchangeRate,
                        radioGroupValue: currentRate.value,
                        icon: CountryFlag(
                          svgAsset: exchangeRate.currency.format.flagSvg,
                          width: 20,
                          height: 20,
                        ),
                        onPressed: () async {
                          currentRate.value = exchangeRate;
                          if (popOnSelect) {
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            popWithResult();
                          }
                        },
                      );
                    }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
