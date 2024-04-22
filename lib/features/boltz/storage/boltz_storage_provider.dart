import 'dart:convert';

import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/boltz/api_models/boltz_api_models.dart';
import 'package:aqua/features/boltz/storage/boltz_swap_secure_data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'boltz_storage_provider.freezed.dart';
part 'boltz_storage_provider.g.dart';

//ANCHOR - Convenience Providers

/// FutureProviders for all swaps
final boltzAllSwapsProvider =
    FutureProvider.autoDispose<List<BoltzSwapData>>((ref) async {
  return ref.watch(boltzDataProvider).getAllSwaps();
});

final boltzAllReverseSwapsProvider =
    FutureProvider.autoDispose<List<BoltzReverseSwapData>>((ref) async {
  return ref.watch(boltzDataProvider).getAllReverseSwaps();
});

/// FutureProvider to fetch BoltzSwapData based on onchainTx
final boltzSwapDataByOnchainTxProvider =
    FutureProvider.family<BoltzSwapData?, String>((ref, onchainTx) async {
  final provider = ref.watch(boltzDataProvider);
  return provider.getBoltzNormalSwapDataByOnchainTx(onchainTx);
});

//ANCHOR - Provider
final boltzDataProvider = Provider<BoltzDataProvider>((ref) {
  return BoltzDataProvider(ref);
});

class BoltzDataProvider {
  final ProviderRef ref;

  BoltzDataProvider(this.ref);

  final _prefs = SharedPreferences.getInstance();

  //ANCHOR - Normal Submarine Swap - Save request and response to shared preferences, and secure data to secure storage
  Future<void> saveBoltzNormalSwapData(BoltzSwapData data, String id) async {
    SharedPreferences prefs = await _prefs;
    prefs.setString('boltzNormalData_$id', jsonEncode(data.toJson()));

    await ref.read(secureStorageProvider).save(
        key: 'boltzNormalSecureData_$id',
        value: jsonEncode(data.secureData.toJson()));
  }

  //ANCHOR - Normal Submarine Swap - Fetch
  Future<BoltzSwapData?> getBoltzNormalSwapData(String id) async {
    SharedPreferences prefs = await _prefs;
    String? boltzDataJson = prefs.getString('boltzNormalData_$id');

    if (boltzDataJson != null) {
      Map<String, dynamic> json = jsonDecode(boltzDataJson);
      json['secureData'] =
          await _fetchAndDecodeSecureData('boltzNormalSecureData_$id');
      return BoltzSwapData.fromJson(json);
    }
    return null;
  }

  // Fetch all normal swaps
  Future<List<BoltzSwapData>> getAllSwaps(
      {bool onlyIncompleteSwaps = false}) async {
    List<BoltzSwapData> swaps = [];
    SharedPreferences prefs = await _prefs;
    Set<String> keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('boltzNormalData_')) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) {
          continue;
        }

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        String id = key.split('_').last;
        Map<String, dynamic>? secureDataMap =
            await _fetchAndDecodeSecureData('boltzNormalSecureData_$id');

        if (secureDataMap == null) {
          continue;
        }

        json['secureData'] = secureDataMap;

        BoltzSwapData swapData = BoltzSwapData.fromJson(json);

        if (onlyIncompleteSwaps &&
            !(swapData.swapStatus.isPending ||
                swapData.swapStatus.needsClaim ||
                swapData.swapStatus.needsRefund)) {
          continue;
        }

        swaps.add(swapData);
      }
    }

    // sort newest first
    swaps.sort((a, b) {
      if (a.created == null) return 1;
      if (b.created == null) return -1;
      return b.created!.compareTo(a.created!);
    });

    return swaps;
  }

  // Fetch `BoltzSwapData` based on the lightning invoice passed to `BoltzCreateSwapRequest`
  Future<BoltzSwapData?> getBoltzNormalSwapDataByInvoice(
      String lightningInvoice) async {
    SharedPreferences prefs = await _prefs;
    Set<String> keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('boltzNormalData_')) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) continue;

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        BoltzCreateSwapRequest request =
            BoltzCreateSwapRequest.fromJson(json['request']);

        if (request.invoice == lightningInvoice) {
          String id = key.split('_').last;
          json['secureData'] =
              await _fetchAndDecodeSecureData('boltzNormalSecureData_$id');

          if (json['secureData'] == null) {
            continue;
          }

          return BoltzSwapData.fromJson(json);
        }
      }
    }

    return null;
  }

  // Fetch `BoltzSwapData` based the completed onchain tx
  // NOTE: This function will NOT fetch secureData as that should be unnecessary once an onchainTx exists
  Future<BoltzSwapData?> getBoltzNormalSwapDataByOnchainTx(
      String onchainTxHash) async {
    SharedPreferences prefs = await _prefs;
    Set<String> keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('boltzNormalData_')) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) continue;

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        String? storedOnchainTxHash = json['onchainTxHash'];

        if (storedOnchainTxHash == onchainTxHash) {
          return BoltzSwapData.fromJson(json);
        }
      }
    }

    return null;
  }

  // Fetch `BoltzReverseSwapData` based the completed onchain tx
  // NOTE: This function will NOT fetch secureData as that should be unnecessary once an onchainTx exists
  Future<BoltzReverseSwapData?> getBoltzReverseSwapDataByOnchainTx(
      String onchainTxHash) async {
    SharedPreferences prefs = await _prefs;
    Set<String> keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('boltzData_')) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) continue;

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        String? storedOnchainTxHash = json['claimTx'];

        if (storedOnchainTxHash == onchainTxHash) {
          return BoltzReverseSwapData.fromJson(json);
        }
      }
    }

    return null;
  }

  //ANCHOR - Reverse Submarine Swap - Save request and response to shared preferences, and secure data to secure storage
  Future<void> saveBoltzReverseSwapData(
      BoltzReverseSwapData data, String id) async {
    SharedPreferences prefs = await _prefs;
    prefs.setString('boltzData_$id', jsonEncode(data.toJson()));

    await ref.read(secureStorageProvider).save(
        key: 'boltzSecureData_$id',
        value: jsonEncode(data.secureData.toJson()));
  }

  //ANCHOR - Reverse Submarine Swap - Fetch
  Future<BoltzReverseSwapData?> getBoltzReverseSwapData(String id) async {
    SharedPreferences prefs = await _prefs;
    String? boltzDataJson = prefs.getString('boltzData_$id');

    if (boltzDataJson != null) {
      Map<String, dynamic> json = jsonDecode(boltzDataJson);
      json['secureData'] =
          await _fetchAndDecodeSecureData('boltzSecureData_$id');
      if (json['secureData'] == null) {
        return null;
      }

      return BoltzReverseSwapData.fromJson(json);
    }
    return null;
  }

  // Fetch all incomplete reverse swaps
  Future<List<BoltzReverseSwapData>> getAllReverseSwaps(
      {bool onlyIncompleteSwaps = false}) async {
    List<BoltzReverseSwapData> swaps = [];
    SharedPreferences prefs = await _prefs;
    Set<String> keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('boltzData_')) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) {
          continue;
        }

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        String id = key.split('_').last;
        Map<String, dynamic>? secureDataMap =
            await _fetchAndDecodeSecureData('boltzSecureData_$id');

        if (secureDataMap == null) {
          continue;
        }

        json['secureData'] = secureDataMap;

        BoltzReverseSwapData swapData = BoltzReverseSwapData.fromJson(json);

        if (onlyIncompleteSwaps &&
            !(swapData.swapStatus.isPending ||
                swapData.swapStatus.needsClaim ||
                swapData.swapStatus.needsRefund)) {
          continue;
        }

        swaps.add(swapData);
      }
    }

    // sort newest first
    swaps.sort((a, b) {
      if (a.created == null) return 1;
      if (b.created == null) return -1;
      return b.created!.compareTo(a.created!);
    });

    return swaps;
  }

  //ANCHOR - Both - Delete
  Future<void> deleteBoltzSwapData(String id) async {
    SharedPreferences prefs = await _prefs;
    prefs.remove('boltzData_$id');
    await ref.read(secureStorageProvider).delete('boltzSecureData_$id');
  }

  //ANCHOR - Fetch Secure Data
  Future<Map<String, dynamic>?> _fetchAndDecodeSecureData(String key) async {
    final (secureDataJson, err) =
        await ref.read(secureStorageProvider).get(key);
    if (err != null) {
      logger
          .e('[Boltz] Error reading secure storage - key: $key - error: $err');
      return null;
    }

    if (secureDataJson == null) {
      return null;
    }

    BoltzSwapSecureData secureData =
        BoltzSwapSecureData.fromJson(jsonDecode(secureDataJson));
    return secureData.toJson();
  }
}

/// Caches the normal swap request, response, and secure data
@freezed
class BoltzSwapData with _$BoltzSwapData {
  const factory BoltzSwapData({
    DateTime? created,
    required BoltzCreateSwapRequest request,
    required BoltzCreateSwapResponse response,
    required BoltzSwapSecureData secureData,
    BoltzGetPairsResponse? fees,
    @BoltzSwapStatusConverter()
    @Default(BoltzSwapStatus.created)
    BoltzSwapStatus swapStatus,
    String? onchainTxHash,
    String? refundTx,
  }) = _BoltzSwapData;

  factory BoltzSwapData.fromJson(Map<String, dynamic> json) =>
      _$BoltzSwapDataFromJson(json);
}

/// Caches the reverse swap request, response, secure data, and added data we need for the claim tx
@freezed
class BoltzReverseSwapData with _$BoltzReverseSwapData {
  const factory BoltzReverseSwapData({
    DateTime? created,
    required BoltzCreateReverseSwapRequest request,
    required BoltzCreateReverseSwapResponse response,
    required BoltzSwapSecureData secureData,
    BoltzGetPairsResponse? fees,
    @BoltzSwapStatusConverter()
    @Default(BoltzSwapStatus.created)
    BoltzSwapStatus swapStatus,
    String? claimTx,
  }) = _BoltzReverseSwapData;

  factory BoltzReverseSwapData.fromJson(Map<String, dynamic> json) =>
      _$BoltzReverseSwapDataFromJson(json);
}

extension BoltzReverseSwapDataExt on BoltzReverseSwapData {
  String? get onchainTxHash => claimTx;
}
