import 'dart:async';

import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

const _blockStreamApiBaseUrl = 'https://blockstream.info';
const _bitcoinPrefix = 'BITCOIN:';
const _liquidPrefix = 'LIQUID:';

class PokerChipAssetError implements Exception {}

class PokerChipInvalidAddressError implements Exception {}

class PokerChipUnexpectedResponseError implements Exception {}

final pokerchipBalanceProvider = AutoDisposeAsyncNotifierProviderFamily<
    PokerchipBalanceNotifier,
    PokerchipBalanceState,
    String>(PokerchipBalanceNotifier.new);

class PokerchipBalanceNotifier
    extends AutoDisposeFamilyAsyncNotifier<PokerchipBalanceState, String> {
  @override
  FutureOr<PokerchipBalanceState> build(String arg) async {
    final scanInput =
        arg.replaceFirst(_bitcoinPrefix, '').replaceFirst(_liquidPrefix, '');
    final isBtc = await ref.read(bitcoinProvider).isValidAddress(scanInput);
    final isLiquid = await ref.read(liquidProvider).isValidAddress(scanInput);

    if (!isBtc && !isLiquid) {
      return Future.error(PokerChipInvalidAddressError());
    }

    final explorerLink = isBtc
        ? '$_blockStreamApiBaseUrl/address/$scanInput'
        : '$_blockStreamApiBaseUrl/liquid/address/$scanInput';
    final apiLink = isBtc
        ? '$_blockStreamApiBaseUrl/api/address/$scanInput/utxo'
        : '$_blockStreamApiBaseUrl/liquid/api/address/$scanInput/utxo';
    final apiResponse = await ref.read(dioProvider).get(apiLink);

    debugPrint('[Pokerchip] Type: ${apiResponse.data.runtimeType}');
    if (apiResponse.data == null || apiResponse.data is! List) {
      return Future.error(PokerChipAssetError());
    }

    final items = apiResponse.data as List;

    if (items.isEmpty) {
      return PokerchipBalanceState(
        address: scanInput,
        balance: '0',
        asset: isBtc ? Asset.btc() : ref.read(manageAssetsProvider).lbtcAsset,
        explorerLink: explorerLink,
      );
    }

    if (items.length != 1) {
      // if there is more than 1 UTXO, we just bail
      return Future.error(PokerChipUnexpectedResponseError());
    }

    final data = items.first;
    if (isBtc) {
      data.addAll({
        'asset': 'btc',
      });
    }

    final pokerChipAssetResponse = PokerChipAssetResponse.fromJson(data);
    final balance = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: pokerChipAssetResponse.value, precision: 8);
    final asset =
        isBtc ? Asset.btc() : await _getUserAsset(pokerChipAssetResponse.asset);

    return PokerchipBalanceState(
      address: scanInput,
      balance: '$balance ${asset.ticker}',
      asset: asset,
      explorerLink: explorerLink,
    );
  }

  Future<Asset> _getUserAsset(String assetId) async {
    final gdkAsset = await ref.read(aquaProvider).liquidAssetById(assetId);
    return ref.read(manageAssetsProvider).allAssets.firstWhere(
          (asset) => asset.id == gdkAsset?.id,
          orElse: () => Asset(
            id: assetId,
            name: assetId,
            ticker: gdkAsset?.ticker ?? '',
            logoUrl: Svgs.unknownAsset,
            isLBTC: false,
            isUSDt: false,
          ),
        );
  }
}
