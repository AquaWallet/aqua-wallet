import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';

part 'feature_flags_service.chopper.dart';

final featureFlagsServiceProvider =
    FutureProvider<FeatureFlagsService>((ref) async {
  final (token, _) =
      await ref.read(secureStorageProvider).get(Jan3AuthNotifier.tokenKey);
  final onUnauthorized = ref.read(jan3AuthProvider.notifier).onUnauthorized;
  return FeatureFlagsService.create(token, onUnauthorized);
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
      String? token, VoidCallback onUnauthorized) {
    final client = ChopperClient(
      baseUrl: Uri.parse(aquaAnkaraProdApiUrl),
      services: [_$FeatureFlagsService()],
      interceptors: [
        HttpLoggingInterceptor(),
        Jan3ApiAuthInterceptor(token),
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
