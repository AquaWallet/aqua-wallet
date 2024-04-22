import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

class BoltzException implements ExceptionLocalized {
  final BoltzExceptionType type;
  final String? customMessage;

  BoltzException(this.type, {this.customMessage});

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case BoltzExceptionType.normalSwapAlreadyBroadcasted:
        return context.loc.boltzNormalSwapAlreadyBroadcastedError;
      case BoltzExceptionType.custom:
        return customMessage ?? toString();
      default:
        throw ('Unhandled boltz service error');
    }
  }
}

enum BoltzExceptionType {
  normalSwapAlreadyBroadcasted,
  custom;
}
