import 'package:coin_cz/features/feature_flags/models/feature_flags_models.dart';
import 'package:coin_cz/features/feature_flags/services/feature_flags_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final ankaraFeatureFlagsProvider = AsyncNotifierProvider.autoDispose<
    AnkaraFeatureFlagsNotifier,
    List<FeatureFlag>>(AnkaraFeatureFlagsNotifier.new);

class AnkaraFeatureFlagsNotifier
    extends AutoDisposeAsyncNotifier<List<FeatureFlag>> {
  @override
  Future<List<FeatureFlag>> build() async {
    final service = await ref.watch(featureFlagsServiceProvider.future);
    final response = await service.getFlags();

    if (!response.isSuccessful) {
      throw Exception('Failed to fetch feature flags');
    }

    return response.body ?? [];
  }

  /// Refreshes the feature flags from the server
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

extension FeatureFlagListExtension on List<FeatureFlag> {
  bool isFlagActive(String flagName) {
    return any(
      (flag) => flag.name == flagName && flag.isActive,
    );
  }
}
