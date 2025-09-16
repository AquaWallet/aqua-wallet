import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';

final electrumServerProvider =
    Provider.autoDispose<ElectrumServerNotifier>((ref) {
  final prefs = ref.watch(prefsProvider);
  final connection = ref.read(aquaConnectionProvider.notifier);
  return ElectrumServerNotifier(prefs, connection);
});

class ElectrumServerNotifier extends ChangeNotifier {
  final UserPreferencesNotifier prefs;
  final AquaConnectionNotifier aquaConnectionNotifier;

  ElectrumServerNotifier(this.prefs, this.aquaConnectionNotifier);

  bool get isCustomElectrumServer =>
      prefs.customElectrumServerBtcUrl != null ||
      prefs.customElectrumServerLiquidUrl != null;

  String get customElectrumServerBtcUrl =>
      prefs.customElectrumServerBtcUrl ?? '';

  String get customElectrumServerLiquidUrl =>
      prefs.customElectrumServerLiquidUrl ?? '';

  Future<void> setElectrumServer(ElectrumConfig config) async {
    prefs.setCustomElectrumServerBtcUrl(config.btcUrl);
    prefs.setCustomElectrumServerLiquidUrl(config.liquidUrl);
    aquaConnectionNotifier.connect();
    notifyListeners();
  }

  Future<void> setDefaultElectrumServerUrls() async {
    prefs.removeCustomElectrumServerUrls();
    notifyListeners();
  }
}
