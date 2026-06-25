import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';

part 'feature_flags_service.chopper.dart';

final featureFlagsServiceProvider =
    FutureProvider<FeatureFlagsService>((ref) async {
  final walletId = ref.watch(currentWalletIdSyncProvider);
  final tokenManager = ref.watch(jan3AuthTokenManagerProvider(walletId));
  final jan3StagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.jan3StagingEnabled));
  return FeatureFlagsService.create(
    tokenManager,
    ref.read(jan3AuthProvider(walletId).notifier).onUnauthorized,
    jan3StagingEnabled,
  );
});

@ChopperApi(baseUrl: '/api/v1/config/')
abstract class FeatureFlagsService extends ChopperService {
  // Feature Flags
  @Get(path: 'flags/')
  Future<Response<List<FeatureFlag>>> getFlags();

  // Switches
  @Get(path: 'switches/')
  Future<Response<List<SwitchType>>> getSwitches();

  // Setup config (includes remote feature flags)
  @Get(path: 'setup/')
  Future<Response<SetupConfig>> getSetup({
    @Query('build') String? buildNumber,
  });

  static FeatureFlagsService create(
    Jan3AuthTokenManager tokenManager,
    VoidCallback onUnauthorized,
    bool jan3StagingEnabled,
  ) {
    final client = ChopperClient(
      baseUrl: Uri.parse(
          jan3StagingEnabled ? aquaAnkaraStagingApiUrl : aquaAnkaraProdApiUrl),
      services: [_$FeatureFlagsService()],
      interceptors: [
        HttpLoggingInterceptor(),
        Jan3ApiAuthInterceptor(tokenManager),
        Jan3ApiResponseInterceptor(onUnauthorized),
      ],
      converter: const JsonToTypeConverter({
        FeatureFlag: FeatureFlag.fromJson,
        SwitchType: SwitchType.fromJson,
        SetupConfig: SetupConfig.fromJson,
        SetupFlag: SetupFlag.fromJson,
      }),
    );
    return _$FeatureFlagsService(client);
  }
}
