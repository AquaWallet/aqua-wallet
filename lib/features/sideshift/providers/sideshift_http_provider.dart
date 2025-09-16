import 'dart:convert';

import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/provider/network_frontend.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideshift/sideshift.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

const baseUrl = sideshiftUrl;
const sideshiftAffiliateId = 'PVmPh4Mp3';

// Errors //////////////////////////////////////////////////////////////////////

abstract class OrderError {}

class GdkTransactionException implements OrderError {
  GdkTransactionException(this.exception);

  final GdkNetworkException exception;
}

class NoPermissionsException implements ExceptionLocalized, OrderError {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftNoPermissionsError;
  }
}

class OrderException implements Exception, OrderError {
  OrderException(this.message);

  final String? message;
}

class OrdersStatusException implements Exception, OrderError {
  OrdersStatusException(this.message);

  final String? message;
}

class OrderQuoteException implements Exception, OrderError {
  OrderQuoteException(this.message);

  final String? message;
}

class LoadAssetsException implements Exception {}

class LoadPairsException implements Exception {}

// Providers //////////////////////////////////////////////////////////////////s
// Sideshift Http

final sideshiftHttpProvider = Provider.autoDispose<SideshiftHttpProvider>((_) {
  return SideshiftHttpProvider();
});

class SideshiftHttpProvider {
  SideshiftHttpProvider();

  Future<List<SideshiftAsset>> fetchSideShiftAssetsList() async {
    const url = "$baseUrl/coins";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final assets = jsonDecode(response.body) as List;
      return assets
          .cast<Map<String, dynamic>>()
          .map((e) => SideshiftAssetResponse.fromJson(e))
          .where((e) => e.networks.isNotEmpty == true)
          .expand((e) =>
              e.networks.map((n) => SideshiftAsset.create(e, network: n)))
          .toSet()
          .toList();
    } else {
      throw LoadAssetsException();
    }
  }

  Future<SideShiftAssetPairInfo> fetchSideShiftAssetPair(
    SideshiftAsset fromAsset,
    SideshiftAsset toAsset,
  ) async {
    logger.debug('[SideShift] Pair ${fromAsset.id}/${toAsset.id}');
    final url = "$baseUrl/pair/${fromAsset.id}/${toAsset.id}";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SideShiftAssetPairInfo.fromJson(json);
    } else {
      throw LoadPairsException();
    }
  }

  Future<SideshiftQuoteResponse> requestQuote({
    required SideshiftAsset fromAsset,
    required SideshiftAsset toAsset,
    Decimal? deliverAmount,
    Decimal? settleAmount,
  }) async {
    const url = "$baseUrl/quotes";
    logger.debug('[SideShift] Requesting order quote: $url');

    final request = SideshiftQuoteRequest(
      depositCoin: fromAsset.coin,
      settleCoin: toAsset.coin,
      depositNetwork: fromAsset.network,
      settleNetwork: toAsset.network,
      depositAmount: deliverAmount?.toStringAsFixed(8),
      settleAmount: settleAmount?.toStringAsFixed(8),
      affiliateId: sideshiftAffiliateId,
    );
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SideshiftQuoteResponse.fromJson(json);
    } else {
      logger.debug('[SideShift] Order Quote Error: ${response.body}');
      String? message;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['error']['message'] as String;
      } catch (e) {
        message = null;
      }
      throw OrderQuoteException(message);
    }
  }

  Future<SideshiftPermissionsResponse> checkPermissions() async {
    const url = '$baseUrl/permissions';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      logger.debug('[SideShift] Check Permissions: $json');
      return SideshiftPermissionsResponse.fromJson(json);
    } else {
      logger.debug('[SideShift] Check Permissions Error: ${response.body}');
      throw NoPermissionsException();
    }
  }

  Future<SideshiftFixedOrderResponse> requestFixedOrder({
    required String quoteId,
    required String receiveAddress,
    String? refundAddress,
    bool checkPermission = false,
  }) async {
    const url = "$baseUrl/shifts/fixed";
    logger.debug('[SideShift] Placing fixed rate order: $url');
    if (checkPermission) {
      final permissions = await checkPermissions();
      if (!permissions.createShift) {
        throw NoPermissionsException();
      }
    }

    final request = SideshiftFixedOrderRequest(
      quoteId: quoteId,
      settleAddress: receiveAddress,
      refundAddress: refundAddress,
      affiliateId: sideshiftAffiliateId,
    );
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SideshiftFixedOrderResponse.fromJson(json);
    } else {
      logger.debug('[SideShift] Fixed Order Error: ${response.body}');
      String? message;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['error']['message'] as String;
      } catch (e) {
        message = null;
      }
      throw OrderException(message);
    }
  }

  Future<SideshiftVariableOrderResponse> requestVariableOrder({
    required String receiveAddress,
    required String depositCoin,
    required String depositNetwork,
    required String settleCoin,
    required String settleNetwork,
    String? refundAddress,
    bool checkPermission = false,
  }) async {
    const url = "$baseUrl/shifts/variable";
    logger.debug('[SideShift] Placing variable rate order: $url');
    if (checkPermission) {
      final permissions = await checkPermissions();
      if (!permissions.createShift) {
        throw NoPermissionsException();
      }
    }

    final request = SideshiftVariableOrderRequest(
      settleAddress: receiveAddress,
      refundAddress: refundAddress,
      settleCoin: settleCoin,
      settleNetwork: settleNetwork,
      depositCoin: depositCoin,
      depositNetwork: depositNetwork,
      affiliateId: sideshiftAffiliateId,
    );
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SideshiftVariableOrderResponse.fromJson(json);
    } else {
      logger.debug('[SideShift] Variable Order Error: ${response.body}');
      String? message;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['error']['message'] as String;
      } catch (e) {
        message = null;
      }
      throw OrderException(message);
    }
  }

  Future<SideshiftOrderStatusResponse> fetchOrderStatus(String orderId) async {
    final url = "$baseUrl/shifts/$orderId";
    logger.debug('[SideShift] Checking order status: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SideshiftOrderStatusResponse.fromJson(json);
    } else {
      logger.debug('[SideShift] Order Status Error: ${response.body}');
      String? message;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['error']['message'] as String;
      } catch (e) {
        message = null;
      }
      throw OrderException(message);
    }
  }
}
