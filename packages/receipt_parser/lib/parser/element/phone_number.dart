import 'package:petitparser/petitparser.dart';

String normalizePhoneNumber(String sequence) {
  final noWhitespace = sequence.replaceAll(RegExp(r'\s+'), '');
  final noEndParen = noWhitespace.replaceAll(RegExp(r'[\)]'), '-');
  final noStartParen = noEndParen.replaceAll(RegExp(r'[\(]'), '');
  return noStartParen;
}

Parser<String> phoneNumberParser() {
  // Accepts either format
  return phoneNumberWithParenthesesParser()
      .or(phoneNumberWithoutParenthesesParser())
      .flatten()
      .map(normalizePhoneNumber);
}

Parser<String> phoneNumberWithoutParenthesesParser() {
  var dash = char('-').trim();
  var digitParser = digit().trim();

  // ###-###-####
  return (digitParser.times(3) & dash & digitParser.times(3) & dash & digitParser.times(4))
      .flatten()
      .map(normalizePhoneNumber);
}

Parser<String> phoneNumberWithParenthesesParser() {
  var openParen = char('(').trim();
  var closeParen = char(')').trim();
  var dash = char('-').trim();
  var digitParser = digit().trim();

  // (###) ###-####
  return (openParen &
          digitParser.times(3) &
          closeParen &
          digitParser.times(3) &
          dash &
          digitParser.times(4))
      .flatten()
      .map(normalizePhoneNumber);
}

Parser<String> skipToPhoneNumberParser() {
  // Skip any characters until a phone number pattern is encountered
  var skipUntilPhoneNumber = any().starLazy(phoneNumberParser()).flatten();

  // After skipping, capture the phone number. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilPhoneNumber
      .seq(phoneNumberParser())
      .map((values) => normalizePhoneNumber(values[1] as String));
}
