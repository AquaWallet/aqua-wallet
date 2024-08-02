import 'package:aqua/config/constants/urls.dart' as urls;
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: urls.aquaApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

class NetworkException implements Exception {
  final String? message;

  NetworkException(this.message);
}
