import 'package:coin_cz/features/shared/shared.dart';

abstract class ErrorLocalized implements Exception {
  String toLocalizedString(BuildContext context);
}
