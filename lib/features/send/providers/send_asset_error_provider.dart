import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/features/shared/shared.dart';

final sendAddressErrorProvider =
    StateProvider.autoDispose<ExceptionLocalized?>((ref) {
  return null;
});

final sendAmountErrorProvider =
    StateProvider.autoDispose<ExceptionLocalized?>((ref) {
  return null;
});
