import 'package:petitparser/petitparser.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/phone_number.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/price.dart';

Parser<String> barcodeParser() {
  // Define a digit sequence that must start and end with a digit, allowing letters in between
  final barcodePattern = digit().trim() &
      (letter().trim() | digit().trim() | whitespace().trim()).starGreedy(digit()) &
      digit().trim();

  return barcodePattern.flatten().map(correctNumericSequence).where((correctedSequence) {
    // Validate the corrected sequence is predominantly digits and meets length criteria
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
  final phoneNumberPattern = phoneNumberParser();
  final pricePattern = priceParser();

  // Skip any input until we find a sequence that is not a phone number or price,
  // indicating a potential barcode
  final skipUntilPotentialBarcode =
      (phoneNumberPattern | pricePattern | any()).starLazy(barcode).flatten();

  return (skipUntilPotentialBarcode & barcode).map((values) => values[1] as String);
}
