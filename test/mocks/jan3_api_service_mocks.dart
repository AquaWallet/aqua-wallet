import 'package:aqua/features/account/account.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockJan3ApiService extends Mock implements Jan3ApiService {}

extension MockMoneyBadgerApiService on MockJan3ApiService {
  void mockDecodeMoneybadgerSuccess({required String lightningAddress}) {
    when(() => decodeMoneybadger(any())).thenAnswer(
      (_) async => Response(
        http.Response('', 200),
        MoneybadgerDecodeResponse(lightningAddress: lightningAddress),
      ),
    );
  }

  void mockDecodeMoneybadgerError() {
    when(() => decodeMoneybadger(any())).thenAnswer(
      (_) async => Response<MoneybadgerDecodeResponse>(
        http.Response('', 400),
        null,
      ),
    );
  }
}

/// Helper to build a successful [Response] with the given body.
Response<T> successResponse<T>(T body) =>
    Response(http.Response('', 200), body);

/// Helper to build a failed [Response] with no body.
Response<T> failureResponse<T>() => Response(http.Response('', 401), null);
