import 'dart:async';

import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

const _blockStreamApiBaseUrl = 'https://blockstream.info';
const _bitcoinPrefix = 'BITCOIN:';
const _liquidPrefix = 'LIQUID:';

// Errors

class PokerChipAssetError implements Exception {}

final pokerchipBalanceProvider = AutoDisposeAsyncNotifierProviderFamily<
    PokerchipBalanceNotifier,
    PokerchipBalanceState,
    String>(PokerchipBalanceNotifier.new);

class PokerchipBalanceNotifier
    extends AutoDisposeFamilyAsyncNotifier<PokerchipBalanceState, String> {
  @override
  FutureOr<PokerchipBalanceState> build(String arg) async {
    final address =
        arg.replaceFirst(_bitcoinPrefix, '').replaceFirst(_liquidPrefix, '');
    final isBtc = await ref.read(bitcoinProvider).isValidAddress(address);
    final response = await _getPokerchipDetails(address, isBtc: isBtc);
    final balance =
        ref.read(formatterProvider).formatAssetAmount(amount: response.value);
    final asset = isBtc ? Asset.btc() : await _getUserAsset(response.asset);
    final explorerLink = await _getExplorerLink(address);

    return PokerchipBalanceState(
      address: address,
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

  Future<PokerChipAssetResponse> _getPokerchipDetails(
    String address, {
    required bool isBtc,
  }) async {
    final url = isBtc
        ? '$_blockStreamApiBaseUrl/api/address/$address/utxo'
        : '$_blockStreamApiBaseUrl/liquid/api/address/$address/utxo';
    final client = ref.read(dioProvider);
    final response = await client.get(url);
    final json = response.data as List;
    final data = json.first as Map<String, dynamic>;
    final containsValue = data.containsKey('value') == true;
    final containsAsset = data.containsKey('asset') == true;
    final isValidBtc = isBtc && containsValue;
    final isValidLiquid = containsAsset && containsValue;
    if (isValidBtc || isValidLiquid) {
      return PokerChipAssetResponse.fromJson(data);
    }
    return Future.error(PokerChipAssetError());
  }

  Future<String> _getExplorerLink(String address) async {
    return await ref.read(bitcoinProvider).isValidAddress(address)
        ? '$_blockStreamApiBaseUrl/address/$address'
        : '$_blockStreamApiBaseUrl/liquid/address/$address';
  }
}
