import 'package:petitparser/petitparser.dart';

Parser<String> barcodeParser() {
  // Start with a digit and allow letters or whitespace, but ensure we capture till the last digit
  final digitThenOther = digit().seq(letter() | whitespace() | digit());
  final letterThenOther = letter().seq(digit() | whitespace());

  // Combine the parsers to ensure we capture a sequence starting with digits and optionally followed by letters or whitespaces
  final combined = whitespace().optional() &
      digit().trim().optional() &
      (digitThenOther | letterThenOther).star() &
      digit().trim().optional() &
      whitespace().optional();

  return combined.flatten().map(correctNumericSequence).where((correctedSequence) {
    // Validation to ensure the corrected sequence is predominantly digits and meets length criteria
    int digitCount = correctedSequence.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount >= (correctedSequence.length * 0.7).floor() && correctedSequence.length >= 4;
  });
}

String correctNumericSequence(String sequence) {
  return sequence
      .toUpperCase()
      .replaceAll('O', '0')
      .replaceAll('C', '0')
      .replaceAll('I', '1')
      .replaceAll('Z', '2')
      .replaceAll('S', '5')
      .replaceAll('D', '0')
      .replaceAll('A', '4')
      .replaceAll('E', '6')
      .replaceAll('U', '0')
      .replaceAll(RegExp(r'\s+'), ''); // Remove all spaces
}

Parser<String> skipToBarcodeParser() {
  final barcode = barcodeParser();

  // Consume any character until a potential barcode sequence is encountered.
  // The logic here should be adjusted to ensure it matches the start of a valid barcode.
  var skipUntilPotentialBarcode = pattern('^-.').starLazy(barcode).flatten();

  // The final parser sequence: skip until a potential barcode is found, then parse the barcode.
  return skipUntilPotentialBarcode.seq(barcode).map((values) => values[1] as String);
}
