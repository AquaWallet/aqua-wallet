import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/features/shared/shared.dart';

final sendAddressErrorProvider =
    StateProvider.autoDispose<ExceptionLocalized?>((ref) {
  return null;
});

final sendAmountErrorProvider =
    StateProvider.autoDispose<AmountParsingException?>((ref) {
  return null;
});
