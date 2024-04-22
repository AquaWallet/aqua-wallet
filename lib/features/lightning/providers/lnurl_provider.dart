import 'dart:convert';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/lightning/lnurl/dart_lnurl.dart';
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
  Future<String?> callLNURLp({
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
      logger.d("[LNURL] error fetching pay request: $e");
      throw LNUrlpException();
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
      final _ = decodeUri(input);
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
