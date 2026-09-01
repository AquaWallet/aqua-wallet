import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/feature_flags/services/feature_flags_service.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:package_info_plus/package_info_plus.dart';

final setupConfigProvider =
    AsyncNotifierProvider<SetupConfigNotifier, SetupConfig>(
        SetupConfigNotifier.new);

Future<SetupConfig> fetchSetupConfig(Ref ref) async {
  final service = await ref.watch(featureFlagsServiceProvider.future);
  final packageInfo = await PackageInfo.fromPlatform();
  final response = await service.getSetup(buildNumber: packageInfo.buildNumber);
  if (!response.isSuccessful || response.body == null) {
    throw Exception('Failed to fetch setup config');
  }
  return response.body!;
}

class SetupConfigNotifier extends AsyncNotifier<SetupConfig> {
  @override
  Future<SetupConfig> build() => fetchSetupConfig(ref);
}

extension SetupFlagListExtension on List<SetupFlag> {
  bool isFlagActive(String flagName) {
    return firstWhereOrNull((f) => f.name == flagName)?.activeAtStart ?? false;
  }
}

final lnAddressRemoteFlagProvider = Provider<bool>((ref) {
  return ref
          .watch(setupConfigProvider)
          .valueOrNull
          ?.flags
          .isFlagActive('ln_address') ??
      false;
});
