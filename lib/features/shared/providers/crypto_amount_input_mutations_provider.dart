import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

final amountInputMutationsProvider =
    Provider.autoDispose(CryptoAmountInputMutationsNotifier.new);

final topUpAmountInputMutationsProvider = Provider.autoDispose((ref) =>
    CryptoAmountInputMutationsNotifier(ref,
        fiatProviderOverride: ref.read(usdFiatProvider)));

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
  }) async {
    // 0 amount is not converted
    if (amountSats == 0 || asset.isAnyUsdt) {
      return null;
    }

    final isFiatInput = isFiatAmountInput ?? false;
    if (isFiatInput) {
      return _ref.read(formatterProvider).formatAssetAmountDirect(
            amount: amountSats,
            precision: asset.precision,
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

    // Crypto to Sats
    return _ref.read(formatterProvider).parseAssetAmountDirect(
          amount: text.isNotEmpty
              ? text
              :
              // text is empty string ("")
              // interpret as 0 sats
              "0",
          precision: asset.precision,
        );
  }
}
