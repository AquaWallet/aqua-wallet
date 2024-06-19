import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';

final sendAddressErrorProvider =
    StateProvider.autoDispose<ExceptionLocalized?>((ref) {
  return null;
});

final sendAmountErrorProvider =
    StateProvider.autoDispose<ExceptionLocalized?>((ref) {
  return null;
});
