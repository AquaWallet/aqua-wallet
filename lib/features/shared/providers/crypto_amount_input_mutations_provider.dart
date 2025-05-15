import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

final amountInputMutationsProvider =
    Provider.autoDispose(CryptoAmountInputMutationsNotifier.new);

class CryptoAmountInputMutationsNotifier {
  const CryptoAmountInputMutationsNotifier(this._ref);

  final Ref _ref;

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

    return _ref.read(fiatProvider).getSatsToFiatDisplay(amountSats, withSymbol);
  }

  Future<int> getConvertedAmountSats({
    required String text,
    required Asset asset,
    required bool isFiatInput,
  }) async {
    if (isFiatInput) {
      // Fiat to Sats
      final fiat = Decimal.tryParse(text) ?? Decimal.zero;
      final sats = await _ref.read(fiatProvider).fiatToSatoshi(asset, fiat);
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
