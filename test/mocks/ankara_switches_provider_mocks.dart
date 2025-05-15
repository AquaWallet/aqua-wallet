import 'package:aqua/features/feature_flags/constants/constants.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/feature_flags/providers/feature_switches_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:aqua/features/shared/shared.dart';

class MockAnkaraSwitchesNotifier extends AsyncNotifier<List<SwitchType>>
    with Mock
    implements AnkaraSwitchesNotifier {
  @override
  Future<List<SwitchType>> build() async {
    return [kMoonInvoiceBtc, kMoonInvoiceLbtc, kMoonInvoiceLusdt]
        .map((flag) => SwitchType(
              id: 1,
              name: flag,
              isActive: true,
              note: 'test',
              created: DateTime.now(),
              modified: DateTime.now(),
              active: true,
            ))
        .toList();
  }
}
