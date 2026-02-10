import 'package:aqua/data/data.dart';
import 'package:aqua/features/private_integrations/debit_card/provider/moon_btc_price_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:decimal/decimal.dart';

final amountInputMutationsProvider =
    Provider.autoDispose(CryptoAmountInputMutationsNotifier.new);

final topUpAmountInputMutationsProvider = Provider.autoDispose((ref) =>
    CryptoAmountInputMutationsNotifier(ref,
        fiatProviderOverride: ref
            .read(moonBtcPriceProvider.notifier)
            .getMoonUsdFiatProvider(ref)));

class CryptoAmountInputMutationsNotifier {
  const CryptoAmountInputMutationsNotifier(this._ref,
      {this.fiatProviderOverride});

  final Ref _ref;
  final FiatProvider? fiatProviderOverride;

  FiatProvider get _fiatProvider =>
      fiatProviderOverride ?? _ref.read(fiatProvider);

  Future<String?> getConvertedAmount({
    required int amountSats,
    required Asset asset,
    bool? isFiatAmountInput,
    bool withSymbol = true,
    SupportedDisplayUnits? displayUnitOverride,
  }) async {
    // 0 amount is not converted
    if (amountSats == 0 || asset.isNonSatsAsset) {
      return null;
    }

    final isFiatInput = isFiatAmountInput ?? false;
    if (isFiatInput) {
      // For fiat input, show crypto conversion using the user's selected display unit
      final displayUnit = displayUnitOverride ??
          _ref.read(displayUnitsProvider).getForcedDisplayUnit(asset);
      return _ref.read(formatProvider).formatAssetAmount(
            amount: amountSats,
            asset: asset,
            displayUnitOverride: displayUnit,
          );
    }

    return _fiatProvider.getSatsToFiatDisplay(amountSats, withSymbol);
  }

  Future<int> getConvertedAmountSats({
    required String text,
    required Asset asset,
    required bool isFiatInput,
  }) async {
    if (isFiatInput) {
      // Fiat to Sats
      final fiat = Decimal.tryParse(text) ?? Decimal.zero;
      final sats = await _fiatProvider.fiatToSatoshi(asset, fiat);
      return sats.toBigInt().toInt();
    }

    final displayUnit =
        _ref.read(displayUnitsProvider).getForcedDisplayUnit(asset);
    // Crypto to Sats
    return _ref.read(formatterProvider).parseAssetAmountToSats(
          amount: text.isNotEmpty
              ? text
              :
              // text is empty string ("")
              // interpret as 0 sats
              "0",
          precision: displayUnit.getDisplayPrecision(asset),
          asset: asset,
        );
  }
}
