import 'dart:convert';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/lightning/lnurl_parser/dart_lnurl_parser.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

final RegExp _regExpForLnAddressConversion =
    RegExp(r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})');
final RegExp _regExpForValidatingAddress =
    RegExp(r'^([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$');

/// lnurlParseResult provider
final lnurlParseResultProvider =
    StateProvider.autoDispose<LNURLParseResult?>((ref) {
  return null;
});

/// Main provider
final lnurlProvider = Provider.autoDispose<LNUrlService>((ref) {
  return LNUrlService(ref);
});

class LNUrlService {
  final AutoDisposeProviderRef ref;

  LNUrlService(this.ref);

  /// Call lnurlPay and returns an invoice
  Future<String?> callLnurlPay({
    required LNURLPayParams payParams,
    required int amountSatoshis,
  }) async {
    int amountMilliSatoshis = amountSatoshis * 1000;
    final client = ref.read(dioProvider);
    try {
      if (payParams.callback == null) {
        throw LNUrlpException();
      }

      final apiResponse = await client.get(payParams.callback!,
          queryParameters: {"amount": amountMilliSatoshis});
      final json = _parseJsonResponse(apiResponse.data);
      logger.d("[LNURL] LNURLp response: $json");
      final response = LNURLPayResult.fromJson(json);
      final invoice = response.pr;
      final bolt11 = Bolt11PaymentRequest(invoice);
      final amount = (bolt11.amount *
          Decimal.fromInt(
              satsPerBtc)); // Bolt11PaymentRequest returns amount in BTC, so convert to sats

      // check amount exists
      if (amount == Decimal.zero) {
        throw AddressParsingException(
            AddressParsingExceptionType.noAmountInInvoice);
      }

      // check amount equals amountSatoshis
      if (amount.toInt() != amountSatoshis) {
        throw AddressParsingException(
            AddressParsingExceptionType.nonMatchingAmountInInvoice);
      }

      return invoice;
    } on DioException catch (_) {
      throw LNUrlpException();
    } catch (e) {
      logger.e("[LNURL] LNURLp error: $e");
      rethrow;
    }
  }

  /// Call lnurlWithdraw
  Future<void> callLnurlWithdraw({
    required LNURLWithdrawParams withdrawParams,
    required String invoice,
  }) async {
    if (withdrawParams.callback == null) {
      throw LNUrlwException;
    }

    final client = ref.read(dioProvider);

    // Construct the full URL with query parameters
    final queryParams = {"k1": withdrawParams.k1, "pr": invoice};
    final uri = Uri.parse(withdrawParams.callback!)
        .replace(queryParameters: queryParams);
    logger.d("[LNURL] LNURLw Requesting URL: ${uri.toString()}");

    try {
      // Lnurl withdraw calls take a while to response
      final options = Options(
        receiveTimeout: const Duration(seconds: 20),
      );
      final apiResponse = await client.getUri(uri, options: options);
      final json = apiResponse.data as Map<String, dynamic>;
      logger.d("[LNURL] LNURLw response: $json");
      final response = LNURLWithdrawResult.fromJson(json);
      if (response.errorResponse != null) {
        throw Exception(response.errorResponse!.reason);
      }

      // LUD-03: withdrawRequest returns either an error or a `{"status": "OK"}` response, so just return if no error
      return;
    } on DioException catch (e) {
      // The lnurlw error is hidden in the dio response error - parse it out
      if (e.response != null) {
        final responseError = LNURLErrorResponse.fromJson(e.response!.data);
        throw Exception(responseError.reason);
      }
      logger.e("[LNURL] LNURLw error: $e");
      // Was seeing a lot of timeouts with no response on successful calls, so if a timeout occurs, just return
      if (e.type == DioExceptionType.receiveTimeout) {
        return;
      }
      throw Exception(e.message);
    }
  }

  /// Tries to convert input to an LNURLp address
  String? convertLnAddressToWellKnown(String lightningAddress) {
    final match = _regExpForLnAddressConversion.firstMatch(lightningAddress);
    if (match != null && match.groupCount == 2) {
      String user = match.group(1)!;
      String domain = match.group(2)!;

      // Construct the .well-known/lnurlp URL
      String lnurlp = 'https://$domain/.well-known/lnurlp/$user';
      logger.d("[LNURL] lnurlp constructed: $lnurlp");
      return lnurlp;
    } else {
      return null;
    }
  }

  /// Check is valid lightning address format. However, since a lightning address `user@jan3.com` is really just in an email format, this is just an email format checker
  bool isValidLightningAddressFormat(String input) {
    return _regExpForValidatingAddress.hasMatch(input);
  }

  /// Check if input is a valid lnurl
  bool isValidLnurl(String input) {
    try {
      decodeLnurlUri(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _parseJsonResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    } else {
      throw const FormatException('Invalid JSON data format');
    }
  }
}

class LNUrlpException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.lnurlpInvoiceRetrievalError;
  }
}

class LNUrlwException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return AppLocalizations.of(context)!.lnurlwGeneralError;
  }
}
