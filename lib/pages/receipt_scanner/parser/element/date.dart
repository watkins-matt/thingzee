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
  // Assume sequence is already in 'YYYY-MM-DD' format or needs conversion from 'MM/DD/YYYY'
  final parts = sequence.split(RegExp(r'[-/]'));
  if (parts.length == 3) {
    if (sequence.contains('/')) {
      // Convert from MM/DD/YYYY to YYYY-MM-DD
      return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
    }
  }

  return sequence;
}

Parser<String> skipToDateParser() {
  // Skip any characters until a date pattern is encountered
  var skipUntilDate = any().starLazy(dateParser()).flatten();

  // After skipping, capture the date. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilDate.seq(dateParser()).map((values) => normalizeDate(values[1] as String));
}
