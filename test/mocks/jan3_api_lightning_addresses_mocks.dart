import 'package:aqua/features/lightning_address/services/services.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockJan3ApiLightningAddresses extends Mock
    implements Jan3ApiLightningAddresses {}

extension MockJan3ApiLightningAddressesX on MockJan3ApiLightningAddresses {
  void mockRegisterAddressesSuccess() {
    when(() => registerAddresses(
          any(),
          overrideFingerprint: any(named: 'overrideFingerprint'),
        )).thenAnswer(
      (_) async => Response(http.Response('', 204), null),
    );
  }

  void mockRegisterAddressesFailure({
    int statusCode = 400,
    String body = 'Invalid Liquid address',
  }) {
    when(() => registerAddresses(
          any(),
          overrideFingerprint: any(named: 'overrideFingerprint'),
        )).thenAnswer(
      (_) async => Response(http.Response(body, statusCode), null),
    );
  }
}
