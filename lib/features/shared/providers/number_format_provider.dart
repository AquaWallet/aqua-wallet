import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:intl/intl.dart';

final currencyFormatProvider =
    Provider.autoDispose.family<NumberFormat, int>((ref, precision) {
  ref.watch(prefsProvider.select((p) => p.languageCode));

  return NumberFormat.currency(
    decimalDigits: precision,
    name: '',
    locale: 'en_US',
  );
});
