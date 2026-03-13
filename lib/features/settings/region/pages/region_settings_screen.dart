import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/settings/region/models/region.dart';
import 'package:aqua/features/settings/region/providers/region_provider.dart';
import 'package:aqua/features/settings/shared/widgets/settings_selection_list.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class RegionSettingsScreen extends HookConsumerWidget {
  static const routeName = '/regionSettingsScreen';

  const RegionSettingsScreen({
    super.key,
    this.isFromMarketplace = false,
  });

  final bool isFromMarketplace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableRegions = ref.watch(availableRegionsProvider);
    final currentRegion =
        ref.watch(regionsProvider.select((p) => p.currentRegion));
    final regionFilter = useMemoized(
      () => (SettingsItem item, String query) {
        if (query.isEmpty) return 0;
        final region = item.object as Region;
        final regionName = region.name.toLowerCase();
        final regionIso = region.iso.toLowerCase();
        final queryLower = query.toLowerCase().trim();
        const aliasNames = {
          'usa': ['united states', 'united states of america'],
          'us': ['united states', 'united states of america'],
          'uk': ['united kingdom', 'great britain'],
          'uae': ['united arab emirates'],
        };
        const aliasIsos = {
          'usa': ['us'],
          'us': ['us'],
          'uk': ['gb', 'uk'],
          'uae': ['ae'],
        };

        final nameCandidates = <String>{
          queryLower,
          ...?aliasNames[queryLower],
        };
        final isoCandidates = <String>{
          queryLower,
          ...?aliasIsos[queryLower],
        };

        final startsWith =
            nameCandidates.any((candidate) => regionName.startsWith(candidate));
        final contains = nameCandidates.any((candidate) =>
            regionName.contains(candidate) &&
            !regionName.startsWith(candidate));
        final isoMatches =
            isoCandidates.any((candidate) => regionIso == candidate);

        if (startsWith || isoMatches) return 0;
        if (contains) return 1;
        return null;
      },
      [],
    );
    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.region,
        colors: context.aquaColors,
      ),
      body: availableRegions.when(
        data: (items) => SettingsSelectionList(
          showSearch: true,
          filter: regionFilter,
          items: [
            if (currentRegion != null) currentRegion,
            ...items.where((r) => r.iso != currentRegion?.iso),
          ]
              .mapIndexed(
                (index, item) => SettingsItem.create(
                  item,
                  name: item.name,
                  index: index,
                  length: items.length,
                ),
              )
              .toList(),
          itemBuilder: (context, item) {
            final region = item.object as Region;
            return SettingsListSelectionItem(
              icon: CountryFlag(
                svgAsset: region.flagSvg,
                size: 20,
              ),
              title: region.name,
              isRadioButton: true,
              radioValue: region.iso,
              radioGroupValue: currentRegion?.iso,
              onPressed: () async {
                await ref.read(regionsProvider).setRegion(region);
                if (!context.mounted) return;
                context.pop();
                if (isFromMarketplace) {
                  ref.read(homeProvider).selectTab(1);
                }
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(context.loc.regionSettingsScreenError),
        ),
      ),
    );
  }
}
