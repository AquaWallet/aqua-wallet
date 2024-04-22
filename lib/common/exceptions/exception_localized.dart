import 'package:aqua/features/shared/shared.dart';

abstract class ExceptionLocalized implements Exception {
  String toLocalizedString(BuildContext context) {
    // default implementation
    return toString();
  }
}
