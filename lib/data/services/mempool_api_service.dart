import 'package:aqua/config/constants/urls.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'mempool_api_service.chopper.dart';

final mempoolBitcoinApiServiceProvider = Provider<MempoolApiService>((ref) {
  return MempoolApiService.create(mempoolSpaceBitcoinUrl);
});

final mempoolLiquidApiServiceProvider = Provider<MempoolApiService>((ref) {
  return MempoolApiService.create(mempoolSpaceLiquidUrl);
});

@ChopperApi(baseUrl: '/api')
abstract class MempoolApiService extends ChopperService {
  static MempoolApiService create(String baseUrl) {
    final client = ChopperClient(
      baseUrl: Uri.parse(baseUrl),
      services: [_$MempoolApiService()],
      interceptors: [
        HttpLoggingInterceptor(),
      ],
      errorConverter: const JsonConverter(),
    );
    return _$MempoolApiService(client);
  }

  /// Fetches the latest block height from Mempool API
  @Get(path: '/blocks/tip/height')
  Future<Response<String>> getLatestBlockHeight();
}
