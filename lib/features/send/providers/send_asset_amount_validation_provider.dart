import 'dart:async';

import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:ui_components/ui_components.dart';

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
    final formatter = ref.read(formatProvider);
    final unitsProvider = ref.read(displayUnitsProvider);
    final currentUnit = unitsProvider.currentDisplayUnit;
    final displayUnitTicker = unitsProvider.getAssetDisplayUnit(asset,
        forcedDisplayUnit: currentUnit);

    if (amount == 0) {
      // Don't throw for zero amounts - this is handled by disabling the send button
      return false;
    }

    if (amount > balance) {
      throw AmountParsingException(AmountParsingExceptionType.notEnoughFunds);
    }

    if (asset.isLBTC && amount < kGdkMinSendAmountLbtcSats) {
      final minAmountFormatted = _formatAmountForError(
        amount: kGdkMinSendAmountLbtcSats,
        asset: asset,
        input: input,
        formatter: formatter,
      );
      throw AmountParsingException(AmountParsingExceptionType.belowLbtcMin,
          amount: minAmountFormatted, displayUnitTicker: displayUnitTicker);
    }

    if (!asset.isLBTC && amount < kGdkMinSendAmountSats) {
      final minAmountFormatted = _formatAmountForError(
        amount: kGdkMinSendAmountSats,
        asset: asset,
        input: input,
        formatter: formatter,
      );
      throw AmountParsingException(AmountParsingExceptionType.belowMin,
          amount: minAmountFormatted, displayUnitTicker: displayUnitTicker);
    }

    final constraints =
        await ref.read(sendAssetAmountConstraintsProvider(arg).future);
    final minServiceSend = constraints.minSats;
    final maxServiceSend = constraints.maxSats;

    if (amount < minServiceSend) {
      final minFormatted = _formatAmountForError(
        amount: minServiceSend,
        asset: asset,
        input: input,
        formatter: formatter,
      );

      throw AmountParsingException(
        AmountParsingExceptionType.belowSendMin,
        amount: minFormatted,
      );
    }

    if (amount > maxServiceSend) {
      final maxFormatted = _formatAmountForError(
        amount: maxServiceSend,
        asset: asset,
        input: input,
        formatter: formatter,
      );

      throw AmountParsingException(
        AmountParsingExceptionType.aboveSendMax,
        amount: maxFormatted,
      );
    }

    return true;
  }

  /// Formats amount for error messages, converting USD to selected currency for USDt
  String _formatAmountForError({
    required int amount,
    required Asset asset,
    required SendAssetInputState input,
    required FormatService formatter,
  }) {
    // USDt in fiat mode needs currency conversion
    if (asset.isUSDt && input.inputType == AquaAssetInputType.fiat) {
      return ref.read(amountInputServiceProvider).formatUsdtAmount(
            amountInSats: amount,
            asset: asset,
            targetCurrency: input.rate.currency,
            currencyFormat: input.rate.currency.format,
            withSymbol: false,
          );
    }

    // For other assets, use standard crypto formatting
    return formatter.formatAssetAmount(
      amount: amount,
      asset: asset,
    );
  }
}
