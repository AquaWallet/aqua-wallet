import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';

enum SupportedDisplayUnits {
  btc('BTC', 0),
  sats('Sats', 8),
  bits('Bits', 6);

  const SupportedDisplayUnits(this.value, this.logDiffToBtc);

  final String value;
  final int logDiffToBtc;
}

final displayUnitsProvider = Provider.autoDispose<DisplayUnitsProvider>((ref) {
  final prefs = ref.watch(prefsProvider);
  return DisplayUnitsProvider(ref, prefs);
});

class DisplayUnitsProvider extends ChangeNotifier {
  final ProviderRef ref;
  final UserPreferencesNotifier prefs;

  DisplayUnitsProvider(this.ref, this.prefs);

  List<SupportedDisplayUnits> get supportedDisplayUnits =>
      SupportedDisplayUnits.values.toList();

  SupportedDisplayUnits get currentDisplayUnit =>
      supportedDisplayUnits.firstWhere(
        (e) => e.value == prefs.displayUnits,
        orElse: () => SupportedDisplayUnits.btc,
      );

  Future<void> setCurrentDisplayUnit(String displayUnits) async {
    prefs.setDisplayUnits(displayUnits);
    notifyListeners();
  }

  SupportedDisplayUnits getForcedDisplayUnit(Asset? asset) {
    if (asset?.isLightning == true) {
      return SupportedDisplayUnits.sats;
    }
    return SupportedDisplayUnits.btc;
  }

  String getAssetDisplayUnit(Asset asset,
      {SupportedDisplayUnits? forcedDisplayUnit}) {
    final shownDisplayUnit = forcedDisplayUnit ?? currentDisplayUnit;
    if (asset.isLBTC) {
      return '${Asset.lbtc().displayUnitPrefix}${shownDisplayUnit.value}';
    }
    if (asset.isNonSatsAsset) {
      return asset.ticker;
    }
    return shownDisplayUnit.value;
  }
}
