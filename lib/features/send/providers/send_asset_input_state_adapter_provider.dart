import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';

// Many future integrations will require the send flow to make transactions.
// This provider functions as an adapter interface to convert the input state
// from other flows into the send flow input state.

final sendAssetInputStateAdapterProvider =
    Provider.autoDispose(SendAssetInputStateAdapterNotifier.new);

class SendAssetInputStateAdapterNotifier {
  SendAssetInputStateAdapterNotifier(this.ref);

  final Ref ref;

  Future<void> fromTopUpInputState({
    required SendAssetArguments arguments,
    required GenerateInvoiceResponse invoice,
    required String address,
  }) async {
    final topUpInput = await ref.read(topUpInputStateProvider.future);
    final amount = topUpInput.isFiatAmountInput
        ? invoice.usdAmountOwed
        : invoice.cryptoAmountOwed;
    final sendInputNotifier = sendAssetInputStateProvider(arguments).notifier;
    ref.read(sendInputNotifier).setTransactionType(SendTransactionType.topUp);
    await ref.read(sendInputNotifier).updateAddressFieldText(address);
    ref.read(sendInputNotifier).setInputType(topUpInput.amountInputType);
    await ref.read(sendInputNotifier).updateAmountFieldText(amount.toString());
  }
}
