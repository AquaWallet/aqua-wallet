import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/account/account.dart';
import 'package:coin_cz/features/feature_flags/models/feature_flags_models.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:chopper/chopper.dart';

part 'feature_flags_service.chopper.dart';

final featureFlagsServiceProvider =
    FutureProvider<FeatureFlagsService>((ref) async {
  final tokenManager = ref.read(jan3AuthTokenManagerProvider);
  return FeatureFlagsService.create(
      tokenManager, ref.read(jan3AuthProvider.notifier).onUnauthorized);
});

@ChopperApi(baseUrl: '/api/v1/')
abstract class FeatureFlagsService extends ChopperService {
  // tiles
  @Get(path: 'marketplace/tiles')
  Future<Response<List<ServiceTilesResponse>>> getMarketPlaceTiles({
    @Query('build') String? buildNumber,
    @Query('region') String? region,
  });

  // Feature Flags
  @Get(path: 'config/flags/')
  Future<Response<List<FeatureFlag>>> getFlags();

  // Switches
  @Get(path: 'config/switches/')
  Future<Response<List<SwitchType>>> getSwitches();

  static FeatureFlagsService create(
    Jan3AuthTokenManager tokenManager,
    VoidCallback onUnauthorized,
  ) {
    final client = ChopperClient(
      baseUrl: Uri.parse(aquaAnkaraProdApiUrl),
      services: [_$FeatureFlagsService()],
      interceptors: [
        HttpLoggingInterceptor(),
        Jan3ApiAuthInterceptor(tokenManager),
        Jan3ApiResponseInterceptor(onUnauthorized),
      ],
      converter: const JsonToTypeConverter({
        FeatureFlag: FeatureFlag.fromJson,
        SwitchType: SwitchType.fromJson,
        ServiceTilesResponse: ServiceTilesResponse.fromJson
      }),
    );
    return _$FeatureFlagsService(client);
  }
}
