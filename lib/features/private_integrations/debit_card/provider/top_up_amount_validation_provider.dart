import 'dart:async';

import 'package:coin_cz/constants.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/address_validator/address_validation.dart';
import 'package:coin_cz/features/private_integrations/private_integrations.dart';
import 'package:coin_cz/features/shared/shared.dart';

// This provider is used to validate the amount input of the top up screen.
// The UI listens to the error events to display messages as a sideeffect.
// The boolean state can be used for decision making such as toggling buttons.

final topUpAmountValidationProvider =
    AutoDisposeAsyncNotifierProvider<TopUpAmountValidationNotifier, bool>(
        TopUpAmountValidationNotifier.new);

class TopUpAmountValidationNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final input = await ref.watch(topUpInputStateProvider.future);
    final asset = input.asset;
    final amount = input.amount;
    final balance = input.balanceInSats;

    if (amount == 0) {
      // Not throwing an error here because this will also be the initial state.
      // Therefore, we should be more forgiving about zero/empty amount inputs
      // than other validations.
      // We will use the state to disable the continue button to prevent
      // user from sending zero amount though.
      return false;
    }

    if (amount > balance) {
      throw AmountParsingException(AmountParsingExceptionType.notEnoughFunds);
    }

    if (amount < kGdkMinSendAmountSats) {
      throw AmountParsingException(AmountParsingExceptionType.belowMin);
    }

    //TODO - Add Moon constraints
    // final constraints =
    //     await ref.read(sendAssetAmountConstraintsProvider(arg).future);
    const minServiceSend = 0;
    final maxServiceSend = double.maxFinite.toInt();

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
