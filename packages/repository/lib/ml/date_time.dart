import 'dart:math';

extension DateTimeExtensions on DateTime {
  // Returns the day of the year (1-365 or 366 for leap years)
  int get dayOfYear {
    return difference(DateTime(year)).inDays + 1;
  }

  // Whether or not this is a leap year
  bool get isLeapYear {
    final year = this.year;
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  List<double> get timeOfYear {
    final dayOfYear = this.dayOfYear;
    final daysInYear = isLeapYear ? 366 : 365;

    final angle = (dayOfYear / daysInYear) * 2 * pi;
    return [sin(angle), cos(angle)];
  }
}
