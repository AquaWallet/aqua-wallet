import 'dart:async';

import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/send/send.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that handles validation error formatting for send asset amounts
final assetValidationErrorProvider =
    Provider.family<String?, AssetValidationErrorParams>(
  (ref, params) {
    if (params.exception == null) {
      return null;
    }

    final decorator = _createDecorator(
      params.decoratorType,
      params.exception!,
      params.balanceDisplay,
    );
    return decorator.toLocalizedString(params.context);
  },
);

class AssetValidationErrorParams {
  const AssetValidationErrorParams({
    required this.exception,
    required this.context,
    required this.decoratorType,
    this.balanceDisplay = '',
  });

  final ExceptionLocalized? exception;
  final BuildContext context;
  final Type decoratorType;
  final String balanceDisplay;
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
  final String? inputFieldError;
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

  void updateErrors(String? tooltipError, String? inputFieldError) {
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
