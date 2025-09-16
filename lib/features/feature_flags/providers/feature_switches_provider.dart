import 'package:coin_cz/features/feature_flags/models/feature_flags_models.dart';
import 'package:coin_cz/features/feature_flags/services/feature_flags_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final ankaraSwitchesProvider =
    AsyncNotifierProvider<AnkaraSwitchesNotifier, List<SwitchType>>(
        AnkaraSwitchesNotifier.new);

class AnkaraSwitchesNotifier extends AsyncNotifier<List<SwitchType>> {
  @override
  Future<List<SwitchType>> build() async {
    try {
      final service = await ref.watch(featureFlagsServiceProvider.future);
      final response = await service.getSwitches();

      if (!response.isSuccessful) {
        throw Exception('Failed to fetch feature switches');
      }

      return response.body ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Refreshes the feature switches from the server
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

extension SwitchTypeListExtension on List<SwitchType> {
  /// Helper method to check if a specific switch is active
  bool isSwitchActive(String switchName) {
    return any(
      (switch_) => switch_.name == switchName && switch_.active,
    );
  }
}
