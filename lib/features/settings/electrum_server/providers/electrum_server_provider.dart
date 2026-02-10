import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

const defaultElectrumServerBtcUrl = '$blockstreamElectrumBaseUrl:700';
const defaultElectrumServerLiquidUrl = '$blockstreamElectrumBaseUrl:995';
const defaultElectrumServerBtcTestnetUrl = '$blockstreamElectrumBaseUrl:993';
const defaultElectrumServerLiquidTestnetUrl = '$blockstreamElectrumBaseUrl:465';

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

  String? get customElectrumServerBtcUrl => prefs.customElectrumServerBtcUrl;

  String? get customElectrumServerLiquidUrl =>
      prefs.customElectrumServerLiquidUrl;

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

  String getElectrumUrl(NetworkType network) {
    switch (network) {
      case NetworkType.bitcoin:
        return customElectrumServerBtcUrl ?? defaultElectrumServerBtcUrl;
      case NetworkType.liquid:
        return customElectrumServerLiquidUrl ?? defaultElectrumServerLiquidUrl;
      case NetworkType.bitcoinTestnet:
        return defaultElectrumServerBtcTestnetUrl;
      case NetworkType.liquidTestnet:
        return defaultElectrumServerLiquidTestnetUrl;
    }
  }
}
