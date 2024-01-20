import 'dart:convert';

import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/external/boltz/api_models/boltz_api_models.dart';
import 'package:aqua/features/external/boltz/storage/boltz_swap_secure_data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

//ANCHOR - Convenience Providers

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
      BoltzCreateSwapRequest request =
          BoltzCreateSwapRequest.fromJson(json['request']);
      BoltzCreateSwapResponse response =
          BoltzCreateSwapResponse.fromJson(json['response']);
      String? onchainTxHash = json['onchainTxHash'] as String?;

      final (secureDataJson, err) = await ref
          .read(secureStorageProvider)
          .get('boltzNormalSecureData_$id');
      if (err != null) {
        logger.e('[Boltz] Error reading secure storage: $err');
        return null;
      }

      if (secureDataJson != null) {
        BoltzSwapSecureData secureData =
            BoltzSwapSecureData.fromJson(jsonDecode(secureDataJson));

        return BoltzSwapData(
            request: request,
            response: response,
            secureData: secureData,
            onchainTxHash: onchainTxHash);
      }
    }

    return null;
  }

  // Fetch `BoltzSwapData` based on the lightning invoice passed to `BoltzCreateSwapRequest`
  Future<BoltzSwapData?> getBoltzNormalSwapDataByInvoice(
      String lightningInvoice) async {
    SharedPreferences prefs = await _prefs;
    Set<String?> keys = prefs.getKeys();
    Iterable<String> nonNullableKeys =
        keys.where((key) => key != null).cast<String>();

    for (String key in nonNullableKeys) {
      if (key.startsWith('boltzNormalData_')) {
        String? boltzDataJson = prefs.getString(key);

        if (boltzDataJson != null) {
          Map<String, dynamic> json = jsonDecode(boltzDataJson);
          BoltzCreateSwapRequest request =
              BoltzCreateSwapRequest.fromJson(json['request']);
          BoltzCreateSwapResponse response =
              BoltzCreateSwapResponse.fromJson(json['response']);

          if (request.invoice == lightningInvoice) {
            String? id = key.split('_').last;

            final (secureDataJson, err) = await ref
                .read(secureStorageProvider)
                .get('boltzNormalSecureData_$id');
            if (err != null) {
              logger.e('[Boltz] Error reading secure storage: $err');
              return null;
            }

            // pass back empty secureData if none
            BoltzSwapSecureData secureData;
            if (secureDataJson != null) {
              secureData =
                  BoltzSwapSecureData.fromJson(jsonDecode(secureDataJson));
            } else {
              secureData = BoltzSwapSecureData(privateKeyHex: '');
            }

            return BoltzSwapData(
                request: request, response: response, secureData: secureData);
          }
        }
      }
    }

    return null;
  }

  // Fetch `BoltzSwapData` based the completed onchain tx `
  Future<BoltzSwapData?> getBoltzNormalSwapDataByOnchainTx(
      String onchainTxHash) async {
    SharedPreferences prefs = await _prefs;
    final keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('boltzNormalData_')) {
        String? boltzDataJson = prefs.getString(key);

        if (boltzDataJson != null) {
          Map<String, dynamic> json = jsonDecode(boltzDataJson);
          BoltzCreateSwapRequest request =
              BoltzCreateSwapRequest.fromJson(json['request']);
          BoltzCreateSwapResponse response =
              BoltzCreateSwapResponse.fromJson(json['response']);
          String? storedOnchainTxHash = json['onchainTxHash'] as String?;

          // Check for secure data
          final (secureDataJson, err) = await ref
              .read(secureStorageProvider)
              .get('boltzNormalSecureData_${response.id}');
          if (err != null) {
            logger.e('[Boltz] Error reading secure storage: $err');
            return null;
          }

          logger.d("[Boltz] boltzNormalSecureData_${response.id}");
          // pass back empty secureData if none
          BoltzSwapSecureData secureData;
          if (secureDataJson != null) {
            secureData =
                BoltzSwapSecureData.fromJson(jsonDecode(secureDataJson));
          } else {
            secureData = BoltzSwapSecureData(privateKeyHex: '');
          }

          if (storedOnchainTxHash != null &&
              storedOnchainTxHash == onchainTxHash) {
            return BoltzSwapData(
                request: request,
                response: response,
                secureData: secureData,
                onchainTxHash: storedOnchainTxHash);
          }
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
      BoltzCreateReverseSwapRequest request =
          BoltzCreateReverseSwapRequest.fromJson(json['request']);
      BoltzCreateReverseSwapResponse response =
          BoltzCreateReverseSwapResponse.fromJson(json['response']);

      final (secureDataJson, err) =
          await ref.read(secureStorageProvider).get('boltzSecureData_$id');
      if (err != null) {
        logger.e('[Boltz] Error reading secure storage: $err');
        return null;
      }

      if (secureDataJson != null) {
        BoltzSwapSecureData secureData =
            BoltzSwapSecureData.fromJson(jsonDecode(secureDataJson));

        return BoltzReverseSwapData(
            request: request, response: response, secureData: secureData);
      }
    }

    return null;
  }

  //ANCHOR - Both - Delete
  Future<void> deleteBoltzSwapData(String id) async {
    SharedPreferences prefs = await _prefs;
    prefs.remove('boltzData_$id');
    await ref.read(secureStorageProvider).delete('boltzSecureData_$id');
  }
}

/// Caches the normal swap request, response, and secure data
class BoltzSwapData {
  final BoltzCreateSwapRequest request;
  final BoltzCreateSwapResponse response;
  final BoltzSwapSecureData secureData;

  final String? onchainTxHash;

  BoltzSwapData({
    required this.request,
    required this.response,
    required this.secureData,
    this.onchainTxHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'response': response.toJson(),
      'onchainTxHash': onchainTxHash,
    };
  }

  // Returns a new instance with the updated onchainTx
  BoltzSwapData withOnchainTxHash(String onchainTxHash) {
    return BoltzSwapData(
      request: request,
      response: response,
      secureData: secureData,
      onchainTxHash: onchainTxHash,
    );
  }
}

/// Caches the reverse swap request, response, secure data, and added data we need for the claim tx
class BoltzReverseSwapData {
  final BoltzCreateReverseSwapRequest request;
  final BoltzCreateReverseSwapResponse response;
  final BoltzSwapSecureData secureData;

  BoltzReverseSwapData({
    required this.request,
    required this.response,
    required this.secureData,
  });

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'response': response.toJson(),
    };
  }
}
