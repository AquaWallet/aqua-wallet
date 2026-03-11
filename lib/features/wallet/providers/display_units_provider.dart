import 'dart:math' as math;

import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';
import 'package:ui_components/models/models.dart';

enum SupportedDisplayUnits {
  btc('BTC', 0, 8, 100000000),
  sats('Sats', 8, 0, 1),
  bits('Bits', 6, 2, 100);

  const SupportedDisplayUnits(
      this.value, this.logDiffToBtc, this.displayPrecision, this.satsPerUnit);

  final String value;
  final int logDiffToBtc;
  final int displayPrecision;
  final int satsPerUnit;

  /// Returns the input precision for a given asset and display unit
  int getDisplayPrecision(Asset? asset) {
    if (asset?.isBTC == true ||
        asset?.isLBTC == true ||
        asset?.isLightning == true) {
      return displayPrecision;
    }
    return asset?.precision ?? 8;
  }

  factory SupportedDisplayUnits.fromAssetInputUnit(AquaAssetInputUnit value) =>
      switch (value) {
        AquaAssetInputUnit.crypto => SupportedDisplayUnits.btc,
        AquaAssetInputUnit.sats => SupportedDisplayUnits.sats,
        AquaAssetInputUnit.bits => SupportedDisplayUnits.bits,
      };
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
    return currentDisplayUnit;
  }

  String getAssetDisplayUnit(Asset asset,
      {SupportedDisplayUnits? forcedDisplayUnit}) {
    final shownDisplayUnit = forcedDisplayUnit ?? currentDisplayUnit;
    if (asset.isLBTC) {
      return '${Asset.lbtc().displayUnitPrefix}${shownDisplayUnit.value}';
    }
    if (asset.isLightning) {
      return '${Asset.lightning().displayUnitPrefix}${shownDisplayUnit.value}';
    }
    if (asset.isNonSatsAsset) {
      return asset.ticker;
    }
    return shownDisplayUnit.value;
  }

  /// Convert satoshis to decimal value based on display unit
  Decimal convertSatsToUnit({
    required int sats,
    required Asset asset,
    SupportedDisplayUnits? displayUnitOverride,
  }) {
    if (asset.isBTC || asset.isLBTC || asset.isLightning) {
      final displayUnit = displayUnitOverride ?? getForcedDisplayUnit(asset);
      return (Decimal.fromInt(sats) / Decimal.fromInt(displayUnit.satsPerUnit))
          .toDecimal();
    }

    return (Decimal.fromInt(sats) /
            Decimal.parse(math.pow(10, asset.precision).toString()))
        .toDecimal();
  }

  int convertUnitToSats({
    required Decimal amount,
    required Asset asset,
    SupportedDisplayUnits? displayUnitOverride,
  }) {
    if (asset.isBTC || asset.isLBTC || asset.isLightning) {
      final displayUnit = displayUnitOverride ?? getForcedDisplayUnit(asset);
      return (amount * Decimal.fromInt(displayUnit.satsPerUnit))
          .toBigInt()
          .toInt();
    }

    return (amount * Decimal.parse(math.pow(10, asset.precision).toString()))
        .toBigInt()
        .toInt();
  }

  /// Convert BTC decimal amount to current display unit string
  String convertBtcToDisplayUnit({
    required Decimal btcAmount,
    required Asset asset,
  }) {
    if (!asset.isBTC && !asset.isLBTC && !asset.isLightning) {
      // For non-BTC assets, just return as string
      return btcAmount.toString();
    }

    // Convert BTC to sats
    final sats = (btcAmount * Decimal.fromInt(100000000)).toBigInt().toInt();

    // Get current display unit
    final displayUnit = getForcedDisplayUnit(asset);

    // Convert sats to display unit
    final displayAmount = convertSatsToUnit(
      sats: sats,
      asset: asset,
    );

    // Format based on display unit
    if (displayUnit == SupportedDisplayUnits.sats) {
      // For sats, return as integer
      return displayAmount.toBigInt().toString();
    } else {
      // For BTC/bits, return as decimal
      return displayAmount.toString();
    }
  }
}

extension SupportedDisplayUnitsX on SupportedDisplayUnits {
  AquaAssetInputUnit toInputUnit() => switch (this) {
        SupportedDisplayUnits.btc => AquaAssetInputUnit.crypto,
        SupportedDisplayUnits.sats => AquaAssetInputUnit.sats,
        SupportedDisplayUnits.bits => AquaAssetInputUnit.bits,
      };
}
