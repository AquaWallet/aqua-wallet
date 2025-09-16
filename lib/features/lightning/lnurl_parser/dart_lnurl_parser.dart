/// Taken and modified from BottlePay implementation: https://github.com/bottlepay/dart_lnurl/tree/master/lib
/// MIT License: https://github.com/bottlepay/dart_lnurl/tree/master?tab=MIT-1-ov-file#readme

library dart_lnurl;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:coin_cz/features/shared/providers/dio_provider.dart';
import 'package:coin_cz/features/lightning/lnurl_parser/src/bech32.dart';
import 'package:coin_cz/features/lightning/lnurl_parser/src/lnurl.dart';
import 'package:bech32/bech32.dart';
import 'package:coin_cz/features/lightning/lnurl_parser/src/types.dart';

export 'src/types.dart';

Uri decodeLnurlUri(String encodedUrl) {
  Uri decodedUri;

  /// The URL doesn't have to be encoded at all as per LUD-17: Protocol schemes and raw (non bech32-encoded) URLs.
  /// https://github.com/lnurl/luds/blob/luds/17.md
  /// Handle non bech32-encoded LNURL
  final lud17prefixes = ['lnurlw', 'lnurlc', 'lnurlp', 'keyauth'];
  decodedUri = Uri.parse(encodedUrl);
  for (final prefix in lud17prefixes) {
    if (decodedUri.scheme.contains(prefix)) {
      decodedUri = decodedUri.replace(scheme: prefix);
    }
  }

  if (lud17prefixes.contains(decodedUri.scheme)) {
    /// If the non-bech32 LNURL is a Tor address, the port has to be http instead of https for the clearnet LNURL so check if the host ends with '.onion' or '.onion.'
    decodedUri = decodedUri.replace(
        scheme: decodedUri.host.endsWith('onion') ||
                decodedUri.host.endsWith('onion.')
            ? 'http'
            : 'https');
  } else {
    /// Try to parse the input as a lnUrl. Will throw an error if it fails.
    final lnUrl = findLnUrl(encodedUrl);

    /// Decode the lnurl using bech32
    final bech32 = const Bech32Codec().decode(lnUrl, lnUrl.length);
    decodedUri = Uri.parse(utf8.decode(fromWords(bech32.data)));
  }

  return decodedUri;
}

/// Get params from a lnurl string. Possible types are:
/// * `LNURLResponse`
/// * `LNURLChannelParams`
/// * `LNURLWithdrawParams`
/// * `LNURLAuthParams`
/// * `LNURLPayParams`
///
/// Throws [ArgumentError] if the provided input is not a valid lnurl.
Future<LNURLParseResult> getParamsFromLnurlServer(Uri encodedUrl) async {
  final dio = createDioInstance(addUserAgent: true);

  try {
    final response = await dio.get(encodedUrl.toString());

    if (response.statusCode! >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    Map<String, dynamic> parsedJson = response.data;

    if (parsedJson['status'] == 'ERROR') {
      return LNURLParseResult(
        error: LNURLErrorResponse.fromJson({
          ...parsedJson,
          ...{
            'domain': encodedUrl.host,
            'url': encodedUrl.toString(),
          }
        }),
      );
    }

    // If it contains a callback then add the domain as a key
    if (parsedJson['callback'] != null) {
      parsedJson['domain'] = Uri.parse(parsedJson['callback']).host;
    }

    if (parsedJson['tag'] == null) {
      throw Exception('Response was missing a tag');
    }

    switch (parsedJson['tag']) {
      case 'withdrawRequest':
        final withdrawalParams = LNURLWithdrawParams.fromJson(parsedJson);
        final result = LNURLParseResult(withdrawalParams: withdrawalParams);
        return result;

      case 'payRequest':
        return LNURLParseResult(
          payParams: LNURLPayParams.fromJson(parsedJson),
        );

      case 'channelRequest':
        return LNURLParseResult(
          channelParams: LNURLChannelParams.fromJson(parsedJson),
        );

      case 'login':
        return LNURLParseResult(
          authParams: LNURLAuthParams.fromJson(parsedJson),
        );

      default:
        if (parsedJson['status'] == 'ERROR') {
          return LNURLParseResult(
            error: LNURLErrorResponse.fromJson({
              ...parsedJson,
              ...{
                'domain': encodedUrl.host,
                'url': encodedUrl.toString(),
              }
            }),
          );
        }

        throw Exception('Unknown tag: ${parsedJson['tag']}');
    }
  } catch (e) {
    if (e is DioException) {
      return LNURLParseResult(
        error: LNURLErrorResponse.fromJson({
          'status': 'ERROR',
          'reason': '${encodedUrl.toString()} returned error: ${e.message}',
          'url': encodedUrl.toString(),
          'domain': encodedUrl.host,
        }),
      );
    } else {
      return LNURLParseResult(
        error: LNURLErrorResponse.fromJson({
          'status': 'ERROR',
          'reason': '${encodedUrl.toString()} returned error: ${e.toString()}',
          'url': encodedUrl.toString(),
          'domain': encodedUrl.host,
        }),
      );
    }
  } finally {
    dio.close();
  }
}
