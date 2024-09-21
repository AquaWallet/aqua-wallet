import 'package:aqua/features/shared/shared.dart';

abstract class ErrorLocalized implements Exception {
  String toLocalizedString(BuildContext context);
}
