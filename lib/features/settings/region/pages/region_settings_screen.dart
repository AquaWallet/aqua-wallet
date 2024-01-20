import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:country_flags/country_flags.dart';

class RegionSettings extends StatelessWidget {
  final Widget child;
  const RegionSettings({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: AppLocalizations.of(context)!.regionSettingsScreenTitle,
      ),
      body: SafeArea(child: child),
    );
  }
}

class RegionSettingsScreen extends HookConsumerWidget {
  static const routeName = '/regionSettingsScreen';

  const RegionSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableRegions = ref.watch(availableRegionsProvider);
    final currentRegion =
        ref.watch(regionsProvider.select((p) => p.currentRegion));

    return RegionSettings(
      child: availableRegions.when(
        data: (items) => SettingsSelectionList(
          showSearch: true,
          label: currentRegion?.name ??
              AppLocalizations.of(context)!.regionSettingsScreenHint,
          items: items
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.name, index: index, length: items.length))
              .toList(),
          itemBuilder: (context, item) {
            final region = item.object as Region;
            return SettingsListSelectionItem(
              icon: CountryFlag.fromCountryCode(
                region.iso,
                width: 20.r,
                height: 20.r,
                borderRadius: 5.r,
              ),
              content: Text(region.name),
              position: item.position,
              onPressed: () => ref.read(regionsProvider).setRegion(region),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(AppLocalizations.of(context)!.regionSettingsScreenError),
        ),
      ),
    );
  }
}
