import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/providers.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class UnitCurrencySettings extends HookConsumerWidget {
  const UnitCurrencySettings({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableCurrencies =
        ref.watch(displayUnitsProvider.select((p) => p.supportedDisplayUnits));
    final currentDisplayUnit =
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AquaText.body1SemiBold(
          text: 'Display Unit',
          color: aquaColors.textPrimary,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final currency = availableCurrencies[index];
              return AquaListItem(
                colors: aquaColors,
                title: currency.name,
                titleColor: aquaColors.textPrimary,
                iconTrailing: AquaRadio<bool>.small(
                  value: currency == currentDisplayUnit,
                  groupValue: true,
                  colors: context.aquaColors,
                ),
                onTap: () async => ref
                    .read(displayUnitsProvider)
                    .setCurrentDisplayUnit(currency.name),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 0),
            itemCount: availableCurrencies.length,
          ),
        ),
        const SizedBox(height: 24),
        AquaText.body1SemiBold(
          text: 'Reference Currency',
          color: aquaColors.textPrimary,
        ),
        const SizedBox(height: 16),
        AquaSearchField(
          hint: 'Search...',
          onChanged: (value) {
            // Handle search query change
          },
        ),
        const SizedBox(height: 16),

        ///TODO: Reference Currency List needs to be loaded from provider

        OutlineContainer(
          aquaColors: aquaColors,
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final currency = availableCurrencies[index];

              ///FIXME: this is just for testing, decision on if there are multiple currencies is from othere sources/providers
              var ifThereAreMultipleCurrencies = index == 2;
              return AquaListItem(
                ///TODO: add flag icon when its avaliable from provider
                // iconLeading: CountryFlag(
                //               svgAsset: flagSvg,
                //               height: 24,
                //               width: 24,
                //             ),
                colors: aquaColors,
                title: 'Name of Currency',
                titleColor: aquaColors.textPrimary,
                subtitle: 'Subtitle name',
                subtitleColor: aquaColors.textSecondary,
                iconTrailing: ifThereAreMultipleCurrencies
                    ? AquaRadio<bool>.small(
                        value: currency == currentDisplayUnit,
                        groupValue: true,
                        colors: context.aquaColors,
                      )
                    : AquaIcon.chevronRight(
                        color: aquaColors.textPrimary,
                      ),
                onTap: () {
                  if (!ifThereAreMultipleCurrencies) {
                    ///TODO: for testing
                    PriceSourceSideSheetWidget.show(
                      context: context,
                      loc: loc,
                      aquaColors: aquaColors,
                      type: PriceSourceExtra.usd,
                    );
                  } else {
                    ///TODO: set currency with provider
                  }
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 0),
            itemCount: availableCurrencies.length,
          ),
        ),
      ],
    );
  }
}

class PriceSourceSideSheetWidget extends StatelessWidget {
  const PriceSourceSideSheetWidget({
    required this.loc,
    required this.aquaColors,
    required this.type,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final PriceSourceExtra type;

  @override
  Widget build(BuildContext context) {
    final mockData = listOfPriceSources[type]!;
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,

      ///TODO: currency type should be passed through constructor and not enum most likely
      title: loc.currencyPriceSource(
        PriceSourceExtra.usd.name.toUpperCase(),
      ),
      showBackButton: false,
      children: List.generate(
        mockData.length,
        (index) {
          final item = mockData[index];

          return AquaListItem(
            colors: aquaColors,
            title: item,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaRadio<bool>.small(
              ///TODO: change to selected from provider
              value: index == 0,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () {
              // Handle tap set new value
            },
          );
        },
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AppLocalizations loc,
    required AquaColors aquaColors,
    required PriceSourceExtra type,
  }) async {
    await SideSheet.right(
      body: PriceSourceSideSheetWidget(
        loc: loc,
        aquaColors: aquaColors,
        type: type,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
