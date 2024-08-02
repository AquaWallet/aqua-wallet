import 'dart:async';
import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    prefs.setString(
      '${BoltzStorageKeys.normalSwapPrefsPrefix}$id',
      jsonEncode(data.toJson()),
    );

    await ref.read(secureStorageProvider).save(
        key: '${BoltzStorageKeys.normalSwapSecureStoragePrefix}$id',
        value: jsonEncode(data.secureData.toJson()));
  }

  //ANCHOR - Normal Submarine Swap - Fetch
  Future<BoltzSwapData?> getBoltzNormalSwapData(String id) async {
    SharedPreferences prefs = await _prefs;
    String? boltzDataJson =
        prefs.getString('${BoltzStorageKeys.normalSwapPrefsPrefix}$id');

    if (boltzDataJson != null) {
      Map<String, dynamic> json = jsonDecode(boltzDataJson);
      json['secureData'] = await fetchAndDecodeSecureData(
          '${BoltzStorageKeys.normalSwapSecureStoragePrefix}$id');
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
      if (key.startsWith(BoltzStorageKeys.normalSwapPrefsPrefix)) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) {
          continue;
        }

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        String id = key.split('_').last;
        Map<String, dynamic>? secureDataMap = await fetchAndDecodeSecureData(
            '${BoltzStorageKeys.normalSwapSecureStoragePrefix}$id');

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
      if (key.startsWith(BoltzStorageKeys.normalSwapPrefsPrefix)) {
        String? boltzDataJson = prefs.getString(key);
        if (boltzDataJson == null) continue;

        Map<String, dynamic> json = jsonDecode(boltzDataJson);
        BoltzCreateSwapRequest request =
            BoltzCreateSwapRequest.fromJson(json['request']);

        if (request.invoice == lightningInvoice) {
          String id = key.split('_').last;
          json['secureData'] = await fetchAndDecodeSecureData(
              '${BoltzStorageKeys.normalSwapSecureStoragePrefix}$id');

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
      if (key.startsWith(BoltzStorageKeys.normalSwapPrefsPrefix)) {
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
        key: '${BoltzStorageKeys.reverseSwapSecureStoragePrefix}$id',
        value: jsonEncode(data.secureData.toJson()));
  }

  //ANCHOR - Reverse Submarine Swap - Fetch
  Future<BoltzReverseSwapData?> getBoltzReverseSwapData(String id) async {
    SharedPreferences prefs = await _prefs;
    String? boltzDataJson = prefs.getString('boltzData_$id');

    if (boltzDataJson != null) {
      Map<String, dynamic> json = jsonDecode(boltzDataJson);
      json['secureData'] = await fetchAndDecodeSecureData(
          '${BoltzStorageKeys.reverseSwapSecureStoragePrefix}$id');
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
        Map<String, dynamic>? secureDataMap = await fetchAndDecodeSecureData(
            '${BoltzStorageKeys.reverseSwapSecureStoragePrefix}$id');

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

  //ANCHOR - Fetch Secure Data
  Future<Map<String, dynamic>?> fetchAndDecodeSecureData(String key) async {
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
