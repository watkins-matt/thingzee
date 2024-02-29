import 'package:petitparser/petitparser.dart';

Parser<String> priceParser() {
  // Matches a digit with optional surrounding spaces.
  var digitWithOptionalSpaces = digit().trim().flatten();

  // Matches at least one digit, allowing spaces between digits.
  var integerPart = digitWithOptionalSpaces.plus().flatten();

  // Optional currency symbol with spaces allowed around it.
  var currencySymbols = pattern('\$€£¥₹₩').optional().trim().flatten();
  var optionalCurrencySymbol = currencySymbols.optional().trim().flatten();

  // Matches the decimal separator (period) with optional spaces, followed by exactly two digits, allowing spaces.
  var decimalPartDigits = digit().seq(whitespace().optional()).seq(digit()).flatten();
  var optionalDecimalPart = char('.')
      .trim() // Allow spaces before the period.
      .seq(decimalPartDigits.trim()) // Allow spaces after the period and between digits.
      .plus()
      .flatten()
      .optional();

  // Modify the integer part to be optional and handle cases where it is absent by prepending "0".
  var modifiedIntegerPart =
      integerPart.optional().map((value) => value != null && value.isEmpty ? '0' : value);

  // Combine all parts to form the price parser.
  var combinedParser =
      (pattern('-').not() & optionalCurrencySymbol & modifiedIntegerPart & optionalDecimalPart)
          .flatten()
          .where((value) {
    return value.contains(RegExp(r'[\$€£¥₹₩]')) || value.contains('.');
  }).map((String value) => value.replaceAll(RegExp(r'\s+|[^\d\.]'), ''));

  // Ensure that if the decimal part is present without an integer part, "0" is prepended.
  return combinedParser.map((String value) => value.startsWith('.') ? '0$value' : value);
}

Parser<String> skipToPriceParser() {
  final parser = priceParser();

  // This parser lazily consumes any characters until it reaches the condition defined in priceParser.
  var skipUntilPrice = any().starLazy(parser).flatten();

  // After skipping, capture the price. The use of .map((values) => values.last) ensures the return type is String.
  return skipUntilPrice.seq(parser).map((values) => values[1] as String);
}
