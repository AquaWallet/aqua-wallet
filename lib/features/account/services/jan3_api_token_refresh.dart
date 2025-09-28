import 'dart:async';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';

part 'jan3_api_token_refresh.chopper.dart';

final jan3RequestTokenApiProvider =
    FutureProvider.autoDispose<Jan3ApiTokenlessService>((ref) async {
  final debitCardStagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.debitCardStagingEnabled));
  return Jan3ApiTokenlessService.create(debitCardStagingEnabled);
});

@ChopperApi(baseUrl: '/api/v1/auth/')
abstract class Jan3ApiTokenlessService extends ChopperService {
  @Post(path: 'refresh/')
  Future<Response<AccessTokenResponse>> refresh(
    @Body() RefreshTokenRequest request,
  );

  static Jan3ApiTokenlessService create(bool debitCardStagingEnabled) {
    final client = ChopperClient(
      baseUrl: Uri.parse(debitCardStagingEnabled
          ? aquaAnkaraStagingApiUrl
          : aquaAnkaraProdApiUrl),
      services: [_$Jan3ApiTokenlessService()],
      interceptors: [
        HttpLoggingInterceptor(),
      ],
      errorConverter: const JsonConverter(),
      converter: const JsonToTypeConverter({
        AccessTokenResponse: AccessTokenResponse.fromJson,
      }),
    );
    return _$Jan3ApiTokenlessService(client);
  }
}
