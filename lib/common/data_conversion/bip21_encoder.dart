import 'dart:math';

import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

const kBip21BasePrecision = 8;

String encodeBip21AmountFromSats({
  required int amountInSats,
  required Asset asset,
}) {
  // First change it back to the original amount.
  final amount = amountInSats / satsPerBtc;
  // Then scale the amount to the base precision.
  // BIP21 for Liquid uses 10^(8-precision) scale for amount parameter.
  // For USDT (precision 8): scale = 10^0 = 1, so amount=10 means 10 USDT.
  // For other asset with precision 2: scale = 10^(8-2) = 10^6, so amount=10 means 0.00001000
  final bip21Amount = amount / pow(10, kBip21BasePrecision - asset.precision);
  return bip21Amount.toString();
}

int decodeBip21AmountToSats({
  required Decimal bip21Amount,
  required Asset asset,
}) {
  final scaleFactor = Decimal.parse(
      BigInt.from(10).pow(kBip21BasePrecision - asset.precision).toString());
  final satsDecimal = bip21Amount * scaleFactor * Decimal.fromInt(satsPerBtc);
  return satsDecimal.toBigInt().toInt();
}

bool validateBip21Amount({
  required int amountInSats,
  required Asset asset,
  required String address,
}) {
  final decoded = Bip21Decoder.decodeOrNull(address);
  if (decoded == null) {
    return true; // not a valid bip21 address
  }
  final decodedAmount = decoded['amount'] as Decimal?;
  if (decodedAmount == null) {
    return true; // no amount means no validation needed
  }
  final decodedNetwork = decoded['network'] as NetworkType?;
  if (decodedNetwork == NetworkType.bitcoin) {
    if (!asset.isBTC) {
      return false; // bitcoin bip21 should only be used with BTC
    }
    final decodedAmountInSats =
        decodeBip21AmountToSats(bip21Amount: decodedAmount, asset: asset);
    return decodedAmountInSats == amountInSats;
  }
  final decodedAssetId = decoded['assetId'] as String?;
  if (decodedAssetId == null) {
    return true; // no asset id means no validation needed
  }
  if (decodedAssetId != asset.id) {
    return false; // asset id mismatch
  }
  final decodedAmountInSats =
      decodeBip21AmountToSats(bip21Amount: decodedAmount, asset: asset);
  return decodedAmountInSats == amountInSats;
}

class Bip21Encoder {
  final String address;
  final Decimal? amount;
  final String? label;
  final String? message;
  final String? lightning;
  // only for liquid
  final Asset? asset;
  final NetworkType network;

  Bip21Encoder({
    required this.address,
    this.amount,
    this.label,
    this.message,
    this.lightning,
    this.asset,
    required this.network,
  });

  String encode() {
    String baseUri =
        (network == NetworkType.bitcoin) ? 'bitcoin:' : 'liquidnetwork:';

    String? amountStr = (amount != null) ? amount.toString() : null;

    Map<String, dynamic> queryParams = {};
    if (amountStr != null) {
      queryParams['amount'] = amountStr;
    }

    if (label != null) {
      queryParams['label'] = label;
    }

    if (message != null) {
      queryParams['message'] = message;
    }

    if (lightning != null) {
      queryParams['lightning'] = lightning;
    }

    if (asset?.id != null) {
      queryParams['assetid'] = asset!.id;
    }

    // Return plain address if no query params
    if (queryParams.isEmpty) {
      return address;
    }

    return Uri.parse('$baseUri$address')
        .replace(queryParameters: queryParams)
        .toString();
  }
}

class Bip21Decoder {
  final String uri;
  late final String address;
  late final Decimal? amount;
  late final String? label;
  late final String? message;
  late final String? lightning;
  late final String? assetId;
  late final NetworkType network;

  Bip21Decoder(this.uri) {
    Map<String, dynamic> decoded = _decode();
    address = decoded['address'];
    amount = decoded['amount'];
    label = decoded['label'];
    message = decoded['message'];
    lightning = decoded['lightning'];
    assetId = decoded['assetId'];
    network = decoded['network'];
  }

  Map<String, dynamic> _decode() {
    List<String> parts = uri.split('?');
    if (parts.length != 2) {
      throw const FormatException('Invalid BIP21 URI');
    }

    String baseUri = parts[0];
    String queryString = parts[1];
    NetworkType network;
    if (baseUri.startsWith('bitcoin:')) {
      network = NetworkType.bitcoin;
    } else if (baseUri.startsWith('liquidnetwork:') ||
        baseUri.startsWith('liquidtestnet:')) {
      network = NetworkType.liquid;
    } else {
      throw const FormatException('Invalid network type');
    }

    String address = baseUri.split(':')[1];
    Map<String, String> queryParameters = Uri.splitQueryString(queryString);

    Decimal? amount = queryParameters.containsKey('amount')
        ? Decimal.parse(queryParameters['amount']!)
        : null;

    if (amount != null && amount < Decimal.zero) {
      throw const FormatException('Invalid amount');
    }

    return {
      'address': address,
      'amount': amount,
      'label': queryParameters['label'],
      'message': queryParameters['message'],
      'lightning': queryParameters['lightning'],
      'assetId': queryParameters['assetid'],
      'network': network,
    };
  }

  static Map<String, dynamic>? decodeOrNull(String? uri) {
    if (uri == null) {
      return null;
    }
    try {
      return Bip21Decoder(uri)._decode();
    } catch (e) {
      return null;
    }
  }
}
