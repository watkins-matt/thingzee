import 'package:petitparser/petitparser.dart';

Parser<String> itemTextParser() {
  final textPattern = letter().trim() &
      (letter() | digit() | pattern(' \'&.')).starGreedy(letter() | newline() | endOfInput()) &
      (letter() | newline() | endOfInput());

  return textPattern.flatten().map((String value) => value.trim());
}

Parser<String> skipToItemTextParser() {
  final parser = itemTextParser();
  final barcode = (letter() | digit()).plus().flatten();

  // Skip any input until we find a sequence that is not a phone number or price,
  // indicating a potential barcode
  final skipUntilPotentialBarcode = (barcode | any()).starLazy(parser).flatten();

  return (skipUntilPotentialBarcode & parser).map((values) => values[1] as String);
}
