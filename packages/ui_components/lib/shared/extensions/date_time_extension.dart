import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String format() {
    return DateFormat('MMM d, yyyy').format(this);
  }
}
