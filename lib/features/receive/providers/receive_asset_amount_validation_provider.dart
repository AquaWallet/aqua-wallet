import 'dart:async';

import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

final receiveAssetAmountValidationProvider =
    AutoDisposeAsyncNotifierProviderFamily<ReceiveAssetAmountValidationNotifier,
        bool, ReceiveAmountArguments>(ReceiveAssetAmountValidationNotifier.new);

class ReceiveAssetAmountValidationNotifier
    extends AutoDisposeFamilyAsyncNotifier<bool, ReceiveAmountArguments> {
  @override
  FutureOr<bool> build(ReceiveAmountArguments arg) async {
    final input = await ref.watch(receiveAssetInputStateProvider(arg).future);
    final asset = arg.asset;

    if (asset.isAltUsdt && arg.minLimit != null && arg.maxLimit != null) {
      final amountFieldText = input.amountFieldText?.replaceAll(',', '');
      if (amountFieldText == null || amountFieldText.isEmpty) {
        return false;
      }

      final amount = Decimal.tryParse(amountFieldText);
      if (amount == null || amount == Decimal.zero) {
        return false;
      }

      await validateAltUsdt(amount, arg);
    } else {
      final amount = input.amountInSats;
      if (amount == 0) {
        return false;
      }

      if (asset.isLightning) {
        await validateLightning(amount, asset);
      }
    }

    return true;
  }

  Future<void> validateAltUsdt(
      Decimal amount, ReceiveAmountArguments arg) async {
    final minLimit = Decimal.tryParse(_extractFirstDecimal(arg.minLimit ?? ''));
    final maxLimit = Decimal.tryParse(_extractFirstDecimal(arg.maxLimit ?? ''));

    if (minLimit != null && amount < minLimit) {
      throw AmountParsingException(
        AmountParsingExceptionType.belowMin,
        amount: arg.minLimit!,
        displayUnitTicker: arg.asset.ticker,
      );
    }

    if (maxLimit != null && amount > maxLimit) {
      throw AmountParsingException(
        AmountParsingExceptionType.aboveSendMax,
        amount: arg.maxLimit!,
        displayUnitTicker: arg.asset.ticker,
      );
    }
  }

  Future<void> validateLightning(int amount, Asset asset) async {
    final reverseFees = await ref.read(boltzReverseFeesProvider.future);
    if (amount < reverseFees.lbtcLimits.minimal.toInt()) {
      throw AmountParsingException(AmountParsingExceptionType.belowMin,
          amount: reverseFees.lbtcLimits.minimal.toInt().toString(),
          displayUnitTicker: asset.ticker);
    }
    if (amount > reverseFees.lbtcLimits.maximal.toInt()) {
      throw AmountParsingException(AmountParsingExceptionType.aboveSendMax,
          amount: reverseFees.lbtcLimits.maximal.toInt().toString(),
          displayUnitTicker: asset.ticker);
    }
  }
}

String _extractFirstDecimal(String text) {
  if (text.isEmpty) return '';
  final match = AquaRegex.firstDecimal.firstMatch(text);
  return match?.group(0) ?? '';
}
