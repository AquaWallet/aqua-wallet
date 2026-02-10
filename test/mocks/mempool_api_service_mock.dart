import 'package:aqua/data/services/mempool_api_service.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockMempoolApiService extends Mock implements MempoolApiService {}

extension MockMempoolApiServiceX on MockMempoolApiService {
  void mockGetLatestBlockHeightSuccess(int height) {
    when(() => getLatestBlockHeight()).thenAnswer((_) async => Response<String>(
          http.Response(height.toString(), 200),
          height.toString(),
        ));
  }

  void mockGetLatestBlockHeightFailure() {
    when(() => getLatestBlockHeight()).thenAnswer((_) async => Response<String>(
          http.Response('error', 500),
          '',
        ));
  }

  void mockGetLatestBlockHeightException() {
    when(() => getLatestBlockHeight()).thenThrow(Exception('Network error'));
  }
}
