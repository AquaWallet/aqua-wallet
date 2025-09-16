import 'package:coin_cz/features/shared/shared.dart';

abstract class ExceptionLocalized implements Exception {
  String toLocalizedString(BuildContext context) {
    // default implementation
    return toString();
  }
}
