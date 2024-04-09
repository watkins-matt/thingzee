import 'package:petitparser/petitparser.dart';

Parser<String> dateParser() {
  // Accepts either MM/DD/YYYY or YYYY-MM-DD format
  return dateWithDashesParser().or(dateWithSlashesParser()).flatten().map(normalizeDate);
}

Parser<String> dateWithDashesParser() {
  var dash = char('-').trim();
  var yearParser = digit().times(4).flatten().trim(); // YYYY
  var monthDayParser = digit().times(2).flatten().trim(); // MM or DD

  // YYYY-MM-DD
  return (yearParser & dash & monthDayParser & dash & monthDayParser).flatten();
}

Parser<String> dateWithSlashesParser() {
  var slash = char('/').trim();
  var monthDayParser = digit().times(2).flatten().trim(); // MM or DD
  var yearParser = digit().times(4).flatten().trim(); // YYYY

  // MM/DD/YYYY
  return (monthDayParser & slash & monthDayParser & slash & yearParser).flatten();
}

String normalizeDate(String sequence) {
  // Split the sequence by either dash (-) or slash (/)
  final parts = sequence.split(RegExp(r'[-/]')).map((part) => part.trim()).toList();
  String year, month, day;

  if (parts.length != 3) return sequence;

  // Determine the format based on the length of the first part
  if (parts[0].length == 4) {
    // Format is assumed to be YYYY-MM-DD or YYYY/MM/DD
    year = parts[0];
    month = parts[1].padLeft(2, '0');
    day = parts[2].padLeft(2, '0');
  } else if (parts[2].length == 4) {
    // Format is assumed to be MM-DD-YYYY or MM/DD/YYYY
    year = parts[2];
    month = parts[0].padLeft(2, '0');
    day = parts[1].padLeft(2, '0');
  }
  // Invalid date format, return the original sequence
  else {
    return sequence;
  }

  // Return the normalized date string
  return '$year-$month-$day';
}

Parser<String> skipToDateParser() {
  // Skip any characters until a date pattern is encountered
  var skipUntilDate = any().starLazy(dateParser()).flatten();

  // After skipping, capture the date. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilDate.seq(dateParser()).map((values) => normalizeDate(values[1] as String));
}
