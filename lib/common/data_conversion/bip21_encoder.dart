import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:decimal/decimal.dart';

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
}
