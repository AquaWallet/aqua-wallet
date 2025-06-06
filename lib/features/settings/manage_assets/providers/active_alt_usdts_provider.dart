import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/settings/manage_assets/providers/manage_assets_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';

final activeAltUSDtsProvider = Provider.autoDispose<List<Asset>>((ref) {
  final preferredService = ref.watch(preferredUsdtSwapServiceProvider);
  final usdtAsset = ref
      .read(manageAssetsProvider)
      .userAssets
      .firstWhereOrNull((asset) => asset.isUSDt);

  if (usdtAsset == null) {
    return [];
  }

  return preferredService.when(
    data: (source) => source.supportedUsdtAssets,
    loading: () => [],
    error: (_, __) => [],
  );
});
