import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';

part 'feature_flags_service.chopper.dart';

final featureFlagsServiceProvider =
    FutureProvider<FeatureFlagsService>((ref) async {
  final tokenManager = ref.read(jan3AuthTokenManagerProvider);
  final debitCardStagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.debitCardStagingEnabled));
  return FeatureFlagsService.create(
      tokenManager,
      ref.read(jan3AuthProvider.notifier).onUnauthorized,
      debitCardStagingEnabled);
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
    bool debitCardStagingEnabled,
  ) {
    final client = ChopperClient(
      baseUrl: Uri.parse(debitCardStagingEnabled
          ? aquaAnkaraStagingApiUrl
          : aquaAnkaraProdApiUrl),
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
