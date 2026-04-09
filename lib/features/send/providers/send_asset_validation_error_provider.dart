import 'dart:async';

import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:ui_components/ui_components.dart';

/// Provider that formats a validation exception as a plain string (e.g. tooltip)
final assetValidationErrorProvider =
    Provider.family<String?, AssetValidationErrorParams>(
  (ref, params) {
    if (params.exception == null) return null;
    final resolved = _makeExceptionDisplay(
      ref,
      params.exception!,
      params.sendInput,
    );
    final decorator = _createDecorator(
      params.decoratorType,
      resolved,
      params.balanceDisplay,
    );
    return decorator.toLocalizedString(params.context);
  },
);

/// Provider that formats a validation exception as a structured [AquaInputError]
/// for display inside the input field, keeping label and amount separate.
final assetInputFieldErrorProvider =
    Provider.family<AquaInputError?, AssetValidationErrorParams>(
  (ref, params) {
    if (params.exception == null) return null;
    final resolved = _makeExceptionDisplay(
      ref,
      params.exception!,
      params.sendInput,
    );
    final decorator = InputFieldExceptionDecorator(
      resolved,
      params.balanceDisplay,
    );
    return decorator.toAquaInputError(params.context);
  },
);

class AssetValidationErrorParams {
  const AssetValidationErrorParams({
    required this.exception,
    required this.context,
    required this.decoratorType,
    this.balanceDisplay = '',
    this.sendInput,
  });

  final ExceptionLocalized? exception;
  final BuildContext context;
  final Type decoratorType;
  final String balanceDisplay;
  final SendAssetInputState? sendInput;
}

/// When [sendInput] is present and the exception carries [AmountParsingException.thresholdSats],
/// fills [amount] / [displayUnitTicker] using the send screen unit ([SendAssetInputState.cryptoUnit]).
ExceptionLocalized _makeExceptionDisplay(
  Ref ref,
  ExceptionLocalized exception,
  SendAssetInputState? sendInput,
) {
  if (exception is! AmountParsingException) return exception;
  final e = exception;
  if (sendInput == null || e.thresholdSats == null) return e;

  final ts = e.thresholdSats!;
  final asset = sendInput.asset;
  final units = ref.read(displayUnitsProvider);
  final displayUnit =
      SupportedDisplayUnits.fromAssetInputUnit(sendInput.cryptoUnit);
  final displayUnitTicker = units.getAssetDisplayUnit(
    asset,
    forcedDisplayUnit: displayUnit,
  );

  final String amountLine;
  if (asset.isUSDt && sendInput.inputType == AquaAssetInputType.fiat) {
    amountLine = ref.read(amountInputServiceProvider).formatUsdtAmount(
          amountInSats: ts,
          asset: asset,
          targetCurrency: sendInput.rate.currency,
          currencyFormat: sendInput.rate.currency.format,
          withSymbol: false,
        );
  } else {
    final unitLabel = asset.isNonSatsAsset ? asset.ticker : displayUnit.value;
    final formatted = ref.read(formatProvider).formatAssetAmount(
          amount: ts,
          asset: asset,
          displayUnitOverride: displayUnit,
          removeTrailingZeros: false,
        );
    amountLine = '$formatted $unitLabel';
  }

  switch (e.type) {
    case AmountParsingExceptionType.belowMin:
    case AmountParsingExceptionType.belowLbtcMin:
      return AmountParsingException(
        e.type,
        amount: amountLine,
        displayUnitTicker: displayUnitTicker,
      );
    case AmountParsingExceptionType.belowSendMin:
    case AmountParsingExceptionType.aboveSendMax:
      return AmountParsingException(e.type, amount: amountLine);
    default:
      return e;
  }
}

T _createDecorator<T extends ExceptionLocalized>(
  Type decoratorType,
  ExceptionLocalized error,
  String balanceDisplay,
) {
  if (decoratorType == TooltipExceptionDecorator) {
    return TooltipExceptionDecorator(error) as T;
  } else if (decoratorType == InputFieldExceptionDecorator) {
    return InputFieldExceptionDecorator(error, balanceDisplay) as T;
  }
  throw ArgumentError('Unsupported decorator type: $decoratorType');
}

class DebouncedErrors {
  const DebouncedErrors({
    this.tooltipError,
    this.inputFieldError,
  });

  final String? tooltipError;
  final AquaInputError? inputFieldError;
}

final debouncedValidationErrorsProvider = StateNotifierProvider.autoDispose
    .family<DebouncedErrorsNotifier, DebouncedErrors, SendAssetArguments>(
  (ref, args) => DebouncedErrorsNotifier(ref),
);

class DebouncedErrorsNotifier extends StateNotifier<DebouncedErrors> {
  DebouncedErrorsNotifier(this.ref) : super(const DebouncedErrors()) {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
  }

  final Ref ref;
  Timer? _debounceTimer;

  void updateErrors(String? tooltipError, AquaInputError? inputFieldError) {
    _debounceTimer?.cancel();

    if (tooltipError == null && inputFieldError == null) {
      state = const DebouncedErrors();
      return;
    }

    final capturedTooltipError = tooltipError;
    final capturedInputFieldError = inputFieldError;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = DebouncedErrors(
          tooltipError: capturedTooltipError,
          inputFieldError: capturedInputFieldError,
        );
      }
    });
  }
}
