import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/settings/region/models/region.dart';
import 'package:aqua/features/settings/region/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class RegionSettings extends HookConsumerWidget {
  const RegionSettings({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final availableRegions = ref.watch(availableRegionsProvider);
    final regionRef = ref.watch(regionsProvider.select(
      (value) => value.currentRegion,
    ));

    return availableRegions.when(
      data: (regions) {
        // Get current search query
        final query =
            useValueListenable(textController).text.trim().toLowerCase();

        // Filter regions based on search query
        final filteredRegions = useMemoized(() {
          if (query.isEmpty) return regions;
          return regions
              .where(
                (region) =>
                    region.name.toLowerCase().contains(query) ||
                    region.iso.toLowerCase().contains(query),
              )
              .toList();
        }, [query, regions]);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AquaSearchField(
              controller: textController,
              hint: 'Search...',
            ),
            const SizedBox(height: 24),
            Flexible(
              child: OutlineContainer(
                aquaColors: aquaColors,
                child: filteredRegions.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final region = filteredRegions[index];
                          final isCurrentRegion = region.iso == regionRef?.iso;

                          return AquaListItem(
                            colors: aquaColors,
                            iconLeading: CountryFlag(
                              svgAsset: region.flagSvg,
                              height: 24,
                              width: 24,
                            ),
                            title: region.name,
                            titleColor: aquaColors.textPrimary,
                            iconTrailing: AquaRadio<bool>.small(
                              value: isCurrentRegion,
                              colors: context.aquaColors,
                            ),
                            onTap: () {
                              ///FIXME: Linux throws error when using this ref
                              // ref
                              //     .read(settings.regionsProvider)
                              //     .setRegion(region);
                            },
                          );
                        },
                        itemCount: filteredRegions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 0),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 38),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AquaIcon.search(
                              color: aquaColors.textSecondary,
                              size: 38,
                            ),
                            const SizedBox(height: 16),
                            AquaText.body1(
                              text: 'No regions found',
                              color: aquaColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            AquaText.body2(
                              text: 'Try searching with a different term',
                              color: aquaColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(context.loc.regionSettingsScreenError),
      ),
    );
  }
}
