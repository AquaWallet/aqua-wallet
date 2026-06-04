import 'dart:async';
import 'dart:math' show max;

import 'package:aqua/constants.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';

// This provider validates the amount input and throws exceptions to block invalid sends.
// The UI layer handles these exceptions to create appropriate validation result objects.

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
      // Don't throw for zero amounts - this is handled by disabling the send button
      return false;
    }

    if (amount > balance) {
      throw AmountParsingException(AmountParsingExceptionType.notEnoughFunds);
    }

    final constraints =
        await ref.read(sendAssetAmountConstraintsProvider(arg).future);
    final minServiceSend = constraints.minSats;
    final maxServiceSend = constraints.maxSats;

    final gdkMin =
        asset.isLayerTwo ? kGdkMinSendAmountLbtcSats : kGdkMinSendAmountSats;
    final bindingMinSats = max(gdkMin, minServiceSend);

    if (amount < bindingMinSats) {
      final AmountParsingExceptionType belowMinType;
      if (minServiceSend > 0 && bindingMinSats == minServiceSend) {
        belowMinType = AmountParsingExceptionType.belowSendMin;
      } else if (asset.isLBTC) {
        belowMinType = AmountParsingExceptionType.belowLbtcMin;
      } else {
        belowMinType = AmountParsingExceptionType.belowMin;
      }
      throw AmountParsingException(
        belowMinType,
        thresholdSats: bindingMinSats,
      );
    }

    if (amount > maxServiceSend) {
      throw AmountParsingException(
        AmountParsingExceptionType.aboveSendMax,
        thresholdSats: maxServiceSend,
      );
    }

    return true;
  }
}
