import 'package:aqua/features/home/providers/home_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MarketplaceRegionSelection extends HookConsumerWidget {
  const MarketplaceRegionSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalTextStyle = useMemoized(() {
      return Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 34.0,
            fontWeight: FontWeight.w500,
            height: 1.25,
          );
    });

    final availableRegions = ref.read(availableRegionsProvider);

    return availableRegions.when(
      data: (items) => Scaffold(
        appBar: AquaAppBar(
          showActionButton: false,
          showBackButton: true,
          title: context.loc.marketplaceTitle,
          onBackPressed: () => ref.read(homeProvider).selectTab(0),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //ANCHOR - Description
              Container(
                padding: const EdgeInsets.only(left: 30.0, bottom: 10.0),
                margin: const EdgeInsets.only(top: 20.0),
                child: Text.rich(
                  TextSpan(
                    text: context
                        .loc.marketplaceRegionScreenDescriptionStartNormal,
                    style: normalTextStyle,
                    children: [
                      TextSpan(
                        text: context.loc.region,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SettingsSelectionList(
                    showSearch: true,
                    label: null,
                    items: items
                        .mapIndexed((index, item) => SettingsItem.create(item,
                            name: item.name,
                            index: index,
                            length: items.length))
                        .toList(),
                    itemBuilder: (context, item) {
                      final region = item.object as Region;
                      return SettingsListSelectionItem(
                        icon: CountryFlag(svgAsset: region.flagSvg),
                        content: Text(
                          region.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        position: item.position,
                        onPressed: () =>
                            ref.read(regionsProvider).setRegion(region),
                      );
                    },
                  ),
                ),
              ),

              // SizedBox(height: 33.0),
            ],
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text(context.loc.regionSettingsScreenError),
      ),
    );
  }
}
