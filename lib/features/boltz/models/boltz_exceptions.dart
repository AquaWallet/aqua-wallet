import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:boltz/boltz.dart';
import 'package:dio/dio.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

class BoltzException implements ExceptionLocalized {
  final BoltzExceptionType type;
  final String? customMessage;

  BoltzException(this.type, {this.customMessage});

  /// Keeps the message the host reported, so the UI can show why it refused.
  factory BoltzException.fromError(Object error) {
    if (error is BoltzException) {
      return error;
    }

    final message = switch (error) {
      BoltzError() => error.message,
      DioException() => error.message ?? error.toString(),
      _ => error.toString(),
    };

    return BoltzException(BoltzExceptionType.custom, customMessage: message);
  }

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case BoltzExceptionType.normalSwapAlreadyBroadcasted:
        return context.loc.boltzNormalSwapAlreadyBroadcastedError;
      case BoltzExceptionType.serviceUnavailable:
        return context.loc.lightningSwapsUnavailableMessage;
      case BoltzExceptionType.custom:
        return customMessage ?? toString();
    }
  }

  String toLocalizedTitle(BuildContext context) {
    switch (type) {
      case BoltzExceptionType.serviceUnavailable:
        return context.loc.lightningSwapsUnavailableTitle;
      case BoltzExceptionType.normalSwapAlreadyBroadcasted:
      case BoltzExceptionType.custom:
        return context.loc.somethingWentWrong;
    }
  }
}

enum BoltzExceptionType {
  normalSwapAlreadyBroadcasted,
  serviceUnavailable,
  custom;
}

/// Runs a call we cannot do Lightning without, such as resolving a host or
/// fetching its fees. Nothing such a call can report is worth showing, so any
/// failure reaches the UI as the shared unavailable prompt.
Future<T> requireBoltzService<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on BoltzException {
    rethrow;
  } catch (e) {
    _logger.error('[Boltz] Service unavailable', e);
    throw BoltzException(BoltzExceptionType.serviceUnavailable);
  }
}

/// Runs a call the host answers on its own terms, such as creating a swap, so
/// its rejection reaches the UI with the reason attached.
Future<T> guardBoltzCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (e) {
    throw BoltzException.fromError(e);
  }
}
