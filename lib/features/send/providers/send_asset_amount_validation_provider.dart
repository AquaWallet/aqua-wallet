import 'dart:async';

import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';

// This provider is used to validate the amount input of the send asset screen.
// The UI listens to the error events to display messages as a sideeffect.
// The boolean state can be used for decision making such as toggling buttons.

final sendAssetAmountValidationProvider =
    AutoDisposeAsyncNotifierProviderFamily<SendAssetAmountValidationNotifier,
        bool, SendAssetArguments>(SendAssetAmountValidationNotifier.new);

class SendAssetAmountValidationNotifier
    extends AutoDisposeFamilyAsyncNotifier<bool, SendAssetArguments> {
  @override
  FutureOr<bool> build(SendAssetArguments arg) async {
    final input = await ref.watch(sendAssetInputStateProvider(arg).future);
    final asset = input.asset;
    final amount = input.amount;
    final balance = input.balanceInSats;

    if (amount == 0) {
      // Not throwing an error here because this will also be the initial state.
      // Therefore, we should be more forgiving about zero/empty amount inputs
      // than other validations.
      // We will use the state to disable the send button to prevent the user
      // from sending zero amount though.
      return false;
    }

    if (amount > balance) {
      throw AmountParsingException(AmountParsingExceptionType.notEnoughFunds);
    }

    if (amount < kGdkMinSendAmountSats) {
      throw AmountParsingException(AmountParsingExceptionType.belowMin);
    }

    final constraints =
        await ref.read(sendAssetAmountConstraintsProvider(arg).future);
    final minServiceSend = constraints.minSats;
    final maxServiceSend = constraints.maxSats;

    if (amount < minServiceSend) {
      throw AmountParsingException(
        AmountParsingExceptionType.belowSendMin,
        amount: ref.read(formatterProvider).formatAssetAmountDirect(
              amount: minServiceSend,
              precision: asset.precision,
            ),
      );
    }

    if (amount > maxServiceSend) {
      throw AmountParsingException(
        AmountParsingExceptionType.aboveSendMax,
        amount: ref.read(formatterProvider).formatAssetAmountDirect(
              amount: maxServiceSend,
              precision: asset.precision,
            ),
      );
    }

    return true;
  }
}
