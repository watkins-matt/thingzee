import 'package:petitparser/petitparser.dart';

Parser<String> skipToZipCodeParser() {
  final parser = zipCodeParser();
  final barcode = (letter() | digit()).plus().flatten();

  // Skip any input until we find a sequence that is not a phone number or price,
  // indicating a potential barcode
  final skipUntilPotentialBarcode = (barcode | any()).starLazy(parser).flatten();

  return (skipUntilPotentialBarcode & parser).map((values) => (values[1] as String).trim());
}

Parser<String> zipCodeParser() {
  // Parser for the initial 5 digits of the ZIP code
  var basicZip = digit().times(5).flatten();

  // Parser for the optional "-XXXX" part of the ZIP+4 code
  var plusFour = char('-') & digit().times(4).flatten();

  // Combine the basic ZIP code parser with the optional +4 extension
  return (basicZip & (plusFour | whitespace() | endOfInput() | newline())).flatten();
}
