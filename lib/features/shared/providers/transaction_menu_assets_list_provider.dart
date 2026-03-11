import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetIds;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:ui_components/ui_components.dart';

const _lightningLabel = 'Bitcoin Lightning';

extension _AssetX on Asset {
  //Predefined order of assets in the transaction menu as per design requirements
  int get assetOrder => switch (this) {
        _ when isBTC => 0,
        _ when isLBTC => 1,
        _ when isLightning => 2,
        _ when isUsdtLiquid => 3,
        _ => 4,
      };
}

final sendMenuAssetsListProvider =
    Provider.autoDispose<Map<AssetUiModel, List<AssetUiModel>>>(
  (ref) => ref.watch(_transactionMenuAssetsListProvider(true)),
);

final receiveAssetsListProvider =
    Provider.autoDispose<Map<AssetUiModel, List<AssetUiModel>>>(
  (ref) => ref.watch(_transactionMenuAssetsListProvider(false)),
);

final _transactionMenuAssetsListProvider = Provider.autoDispose
    .family<Map<AssetUiModel, List<AssetUiModel>>, bool>((ref, isSend) {
  final List<Asset> assets;
  if (isSend) {
    final userAssets = ref.watch(assetsProvider).valueOrNull ?? [];
    //NOTE - Use a copy of the user assets list to avoid mutating the original
    final items = List<Asset>.from(userAssets);
    final isMissingLightning = items.none((asset) => asset.isLightning);
    final containsLbtc = items.any((asset) => asset.isLBTC);
    if (isMissingLightning && containsLbtc) {
      //Lightning does not have a balance of its own and uses LBTC balance
      final lbtcAsset = items.firstWhere((asset) => asset.isLBTC);
      items.add(Asset.lightning(amount: lbtcAsset.amount));
    }
    assets = items;
  } else {
    assets = ref.watch(manageAssetsProvider.select((p) => p.curatedAssets));
  }
  final sortedAssets =
      assets.sorted((a, b) => a.assetOrder.compareTo(b.assetOrder));
  final altUSDtAssets =
      ref.watch(activeAltUSDtsProvider).map((asset) => asset.toUiModel());
  final displayUnit =
      ref.read(displayUnitsProvider.select((p) => p.currentDisplayUnit));

  return Map.fromEntries(sortedAssets.map((asset) => MapEntry(
        asset
            //The top-level USDt is actually just a read-only expandable panel
            //with USDt Tether branding, while the real USDt asset is under the
            //child list.
            .copyWith(id: asset.isUsdtLiquid ? AssetIds.usdtTether : asset.id)
            .toUiModel(
              //Lightning asset name has to be overridden due to design requirements
              name: asset.isLightning ? _lightningLabel : asset.name,
              //Fiat amount and display unit are only needed for send menu
              amountCrypto: ref.watch(formatProvider).formatAssetAmount(
                    amount: asset.amount,
                    asset: asset,
                    removeTrailingZeros: false,
                    displayUnitOverride: displayUnit,
                    decimalPlacesOverride: asset.isAnyUsdt
                        ? kUsdtDisplayPrecision
                        : asset.precision.clamp(0, 8),
                  ),
              amountFiat: isSend
                  ? ref
                      .watch(conversionProvider((
                        // Use LBTC fiat value for Lightning asset
                        asset.isLightning
                            ? assets.firstWhere((a) => a.isLBTC)
                            : asset,
                        asset.amount,
                      )))
                      ?.formattedWithCurrency
                  : null,
              displayUnit: displayUnit.value,
            ),
        asset.isUsdtLiquid
            ? [asset.toUiModel(name: 'Liquid USDt'), ...altUSDtAssets]
            : <AssetUiModel>[],
      )));
});

final filteredFlatAssetsProvider =
    Provider.autoDispose.family<Map<AssetUiModel, List<AssetUiModel>>, Asset?>(
  (ref, filterAsset) {
    final allAssets = ref.watch(receiveAssetsListProvider);

    // Filter assets based on filterAsset
    final assets = filterAsset == null
        ? allAssets
        : Map.fromEntries(
            allAssets.entries.where((entry) {
              if (filterAsset.isAnyUsdt) {
                return entry.key.isUSDt;
              }
              if (filterAsset.isLBTC) {
                return entry.key.isLBTC ||
                    entry.key.assetId == AssetIds.lightning;
              }
              if (filterAsset.isBTC) {
                return entry.key.assetId == AssetIds.btc;
              }
              return entry.key.assetId == filterAsset.id;
            }),
          );

    // De-nest ALL assets - flatten parent/child structure
    // Add each child as a separate top-level entry
    // Keep assets without children as they are
    final result = <AssetUiModel, List<AssetUiModel>>{};
    for (final entry in assets.entries) {
      if (entry.value.isNotEmpty) {
        for (final child in entry.value) {
          result[child] = <AssetUiModel>[];
        }
      } else {
        result[entry.key] = <AssetUiModel>[];
      }
    }

    return result;
  },
);

final selectedAssetProvider =
    StateNotifierProvider.autoDispose<SelectedAssetIdNotifier, Asset?>(
        SelectedAssetIdNotifier.new);

class SelectedAssetIdNotifier extends StateNotifier<Asset?> {
  SelectedAssetIdNotifier(this._ref) : super(null);

  final Ref _ref;

  void selectAsset(String? id) {
    state = null;
    if (id != null) {
      if (id == AssetIds.usdtTether) {
        state = null;
        return;
      }

      final assets = _ref.read(manageAssetsProvider).curatedAssets;
      if (AssetIds.usdtliquid.contains(id)) {
        state = assets.firstWhere((asset) => asset.isUsdtLiquid);
      } else if (AssetIds.isAnyUsdt(id)) {
        final altUSDtAssets = _ref.read(activeAltUSDtsProvider);
        state = altUSDtAssets.firstWhere((asset) => asset.id == id);
      } else {
        state = assets.firstWhere((asset) => id == asset.id);
      }
    }
  }
}
