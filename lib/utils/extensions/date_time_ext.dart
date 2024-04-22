// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeEx on DateTime {
  DateTime get localDate => toLocal();

  String yMd({required Locale locale}) =>
      DateFormat.yMd(locale.languageCode).format(localDate);

  bool isSameDay(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    } else {
      return localDate.year == dateTime.localDate.year &&
          localDate.month == dateTime.localDate.month &&
          localDate.day == dateTime.localDate.day;
    }
  }

  bool get isToday => isSameDay(DateTime.now().localDate);

  String formattedDate() => DateFormat('dd/MM/yyyy').format(localDate);

  String formatShortDate() => DateFormat('dd/MM').format(localDate);

  String formatFullDate() => DateFormat('MMMM d, yyyy').format(localDate);

  String get formatFullDateTime =>
      DateFormat('MMMM d, yyyy hh:mm a').format(localDate);

  String formatShortDayOfWeek() => DateFormat('EEE').format(localDate);

  String formatMonthAndYear() => DateFormat('MMMM yyyy').format(localDate);

  String formatMonthAndYearShort() => DateFormat('MMM yyyy').format(localDate);

  String formatMonth() => DateFormat('MMMM').format(
        localDate,
      );

  String formatShortMonth() => DateFormat('MMM').format(
        localDate,
      );

  String formattedTime() => DateFormat('hh:mm a').format(localDate);

  String formattedHour() => DateFormat('hh a').format(this);

  String formattedFullDateTwoLines() =>
      DateFormat('EEEE\nMMMM dd, yyyy').format(localDate);

  String formattedFullDateWithDaySuffix() =>
      DateFormat("EEEE, MMMM dd'${getDayOfMonthSuffix(day)}'")
          .format(localDate);

  String formatDayOfWeek() => DateFormat(DateFormat.WEEKDAY).format(localDate);

  String formatDayAndMonth() => DateFormat('d MMM').format(localDate);

  String get formatQueryDate => DateFormat('yyyy-MM-dd').format(localDate);

  String get formatQueryDateTime =>
      DateFormat('yyyy-MM-dd hh:mm a').format(localDate);

  String ddMMMMyyyy() => DateFormat('dd MMMM yyyy').format(localDate);

  String yMMMd() => DateFormat('yMMMd').format(localDate);

  String yMMMdHm() => DateFormat('yMMMd HH:mm').format(localDate);

  String HHmmaUTC() => DateFormat('HH:mm a \'UTC\'').format(localDate);

  String formatDay() => DateFormat('d').format(localDate);

  String getFormattedTimeRange(
    DateTime? endDate,
  ) {
    if (endDate == null) {
      return formattedTime();
    } else {
      return '${formattedTime()} - ${endDate.formattedTime()}';
    }
  }

  String getFormattedDateRange(
    DateTime? endDate,
  ) {
    if (endDate == null || endDate.isSameDay(this)) {
      return formatDayAndMonth();
    } else {
      final formattedStartDate = formatDayAndMonth();
      final formattedEndDate = endDate.formatDayAndMonth();
      return '$formattedStartDate - $formattedEndDate';
    }
  }

  DateTime get beginningOfWeek =>
      subtract(Duration(days: weekday - 1)).withoutTime;

  DateTime get beginningOfMonth => DateTime(year, month);

  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  DateTime get endOfWeek => beginningOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59),
      );

  DateTime get withoutTime => DateTime(year, month, day);

  int daysBetween(DateTime to) {
    final startDate = DateTime(year, month, day);
    final endDate = DateTime(to.year, to.month, to.day);
    return (endDate.difference(startDate).inHours / 24).round();
  }

  TimeOfDay extractTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  DateTime combineTimeOfDay(TimeOfDay? timeOfDay) {
    if (timeOfDay == null) {
      return this;
    } else {
      return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
    }
  }

  bool get isYesterday {
    final yesterday =
        DateTime.now().toLocal().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }

  String get formattedDateTime {
    return DateFormat.yMMMMd().format(localDate);
  }

  String getDayOfMonthSuffix(int dayNum) {
    if (!(dayNum >= 1 && dayNum <= 31)) {
      throw Exception('Invalid day of month');
    }

    if (dayNum >= 11 && dayNum <= 13) {
      return 'th';
    }

    switch (dayNum % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  DateTime addTimeOfDay(TimeOfDay? timeOfDay) {
    if (timeOfDay == null) {
      return this;
    }
    return copyWith(
      hour: timeOfDay.hour,
      minute: timeOfDay.minute,
    );
  }

  String dayOfWeekWithFullDate() {
    final fullDate = DateFormat('yMd').format(this);
    final day = DateFormat('E').format(this);
    return '$day $fullDate';
  }
}
