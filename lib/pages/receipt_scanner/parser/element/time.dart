import 'package:petitparser/petitparser.dart';

Parser<String> skipToTimeParser() {
  // Skip any characters until a time pattern is encountered
  var skipUntilTime = any().starLazy(timeParser()).flatten();

  // After skipping, capture the time.
  return skipUntilTime.seq(timeParser()).map((values) => (values[1] as String).trim());
}

Parser<String> timeParser() {
  var hourParser = digit().times(2).flatten().trim(); // HH
  var minuteParser = digit().times(2).flatten().trim(); // MM
  var secondParser = (char(':') & digit().times(2).flatten()).optional().trim(); // Optional :SS
  var amPmParser = (string('AM') | string('PM')).optional().trim(); // Optional AM/PM

  // HH:MM(:SS)? (AM|PM)?
  return (hourParser & char(':') & minuteParser & secondParser & amPmParser).flatten();
}

extension TimeConversion on String {
  /// Converts a time string to a 24-hour format.
  /// Accepts input in both 24-hour and AM/PM formats.
  String to24HourTime() {
    final timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$');
    final match = timePattern.firstMatch(this);

    if (match == null) return 'Invalid Time Format';

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    int? second = match.group(3) != null ? int.parse(match.group(3)!) : null;
    String? amPm = match.group(4);

    if (amPm != null) {
      if (amPm == 'AM' && hour == 12) hour = 0;
      if (amPm == 'PM' && hour != 12) hour += 12;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}${second != null ? ':${second.toString().padLeft(2, '0')}' : ''}';
  }

  /// Converts a time string to an AM/PM format.
  /// Accepts input in both 24-hour and AM/PM formats.
  String toAmPmTime() {
    final timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$');
    final match = timePattern.firstMatch(this);

    if (match == null) return 'Invalid Time Format';

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    int? second = match.group(3) != null ? int.parse(match.group(3)!) : null;
    String amPm = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    // Use padLeft to ensure the hour is always two digits
    String formattedHour = hour.toString().padLeft(2, '0');
    String formattedMinute = minute.toString().padLeft(2, '0');
    String optionalSeconds = second != null ? ':${second.toString().padLeft(2, '0')}' : '';

    return '$formattedHour:$formattedMinute$optionalSeconds $amPm';
  }
}
