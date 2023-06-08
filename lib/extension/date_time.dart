extension Normalize on DateTime {
  DateTime normalize() {
    return DateTime(year, month, day);
  }

  DateTime atHour(int hour) {
    return normalize().add(Duration(hours: hour));
  }

  // Returns the milliseconds since epoch of the normalized date
  int get datestamp => normalize().millisecondsSinceEpoch;
}
