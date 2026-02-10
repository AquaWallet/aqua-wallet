import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:ui_components/ui_components.dart';

// Many future integrations will require the send flow to make transactions.
// This provider functions as an adapter interface to convert the input state
// from other flows into the send flow input state.

final sendAssetInputStateAdapterProvider =
    Provider.autoDispose(SendAssetInputStateAdapterNotifier.new);

class SendAssetInputStateAdapterNotifier {
  SendAssetInputStateAdapterNotifier(this.ref);

  final Ref ref;

  static const int _satsPerBtc = 100000000;
  static const int _bitsPerBtc = 1000000;
  String _convertBtcAmountToDisplayString(double btcAmount, Asset asset) {
    if (!asset.isBTC && !asset.isLBTC) {
      return btcAmount.toString();
    }

    final displayUnit =
        ref.read(displayUnitsProvider).getForcedDisplayUnit(asset);

    return switch (displayUnit) {
      SupportedDisplayUnits.sats =>
        (btcAmount * _satsPerBtc).round().toString(),
      SupportedDisplayUnits.bits => (btcAmount * _bitsPerBtc).toString(),
      _ => btcAmount.toString(),
    };
  }

  Future<void> fromTopUpInputState({
    required SendAssetArguments arguments,
    required GenerateInvoiceResponse invoice,
    required String address,
  }) async {
    final amount = invoice.cryptoAmountOwed;
    final amountText =
        _convertBtcAmountToDisplayString(double.parse(amount), arguments.asset);
    final sendInputNotifier = sendAssetInputStateProvider(arguments).notifier;
    ref.read(sendInputNotifier).setTransactionType(SendTransactionType.topUp);
    await ref.read(sendInputNotifier).updateAddressFieldText(address);
    ref.read(sendInputNotifier).setType(AquaAssetInputType.crypto);
    ref.read(sendInputNotifier).updateAmountFieldText(amountText);
  }
}
