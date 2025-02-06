import 'dart:io';
import 'dart:convert';

import 'package:aqua/config/constants/urls.dart' as urls;
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Dio createDioInstance({
  bool addUserAgent = false,
  bool enableCurlLogging = false,
  FeatureFlag? loggerFlag,
}) {
  final baseOptions = BaseOptions(
    baseUrl: urls.aquaApiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );

  if (addUserAgent) {
    baseOptions.headers['User-Agent'] =
        'AquaWallet(Flutter; ${Platform.operatingSystem})';
  }

  final dio = Dio(baseOptions);

  if (enableCurlLogging) {
    dio.interceptors.add(
        CurlLogInterceptor(CustomLogger(loggerFlag ?? FeatureFlag.network)));
  }

  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  return createDioInstance();
});

class NetworkException implements Exception {
  final String? message;

  NetworkException(this.message);
}

/// CURL command for debugging
///
/// Instantiate dio like this to log CURLs:
///dart
/// final dio = createDioInstance(
///   enableCurlLogging: true,
///   loggerFlag: FeatureFlag.btcDirect,
/// )..options.baseUrl = baseUrl;
/// ```

extension RequestOptionsToCurl on RequestOptions {
  String toCurl() {
    var curl = 'curl -X ${method.toUpperCase()} ';

    // Add headers
    headers.forEach((key, value) {
      if (value != null) {
        curl += "-H '$key: $value' ";
      }
    });

    // Add request body if present
    if (data != null) {
      if (data is Map || data is List) {
        curl += "-d '${jsonEncode(data)}' ";
      } else {
        curl += "-d '$data' ";
      }
    }

    // Add URL
    curl += "'${uri.toString()}'";

    return curl;
  }
}

class CurlLogInterceptor extends Interceptor {
  final CustomLogger _logger;

  CurlLogInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('CURL command:\n${options.toCurl()}');
    handler.next(options);
  }
}
