import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/barcode.dart';

void main() {
  group('barcodeParser tests', () {
    test('Linter for barcodeParser', () {
      final parser = barcodeParser();
      expect(linter(parser), isEmpty);
    });

    test('Returns null for empty input', () {
      final parser = barcodeParser();
      final result = parser.parse('');
      expect(result, isA<Failure>());
    });

    test('Returns null for non-digit input', () {
      final parser = barcodeParser();
      final result = parser.parse('ABC');
      expect(result, isA<Failure>());
    });

    test('Returns null for input with less than half digits', () {
      final parser = barcodeParser();
      final result = parser.parse('123WXY');
      expect(result, isA<Failure>());
    });

    test('Returns the correct barcode for valid input', () {
      final parser = barcodeParser();
      final result = parser.parse('123456');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Corrects small numeric sequence with letter substitutions', () {
      final parser = barcodeParser();
      final result = parser.parse('0D00');
      expect(result, isA<Success>());
      expect(result.value, equals('0000'));
    });

    test('Corrects numeric sequence with letter substitutions', () {
      final parser = barcodeParser();
      final result = parser.parse('0123D123');
      expect(result, isA<Success>());
      expect(result.value, equals('01230123'));

      final result2 = parser.parse('012D123');
      expect(result2, isA<Success>());
      expect(result2.value, equals('0120123'));
    });

    test('Removes whitespace from the input', () {
      final parser = barcodeParser();
      final result = parser.parse(' 1 2 3 4 5 6 ');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Correctly parse the text 123456 T2', () {
      final parser = barcodeParser();
      final result = parser.parse('123456 T2');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });
  });

  group('skipToBarcodeParser tests', () {
    test('Linter for skipToBarcodeParser', () {
      final parser = skipToBarcodeParser();
      expect(linter(parser), isEmpty);
    });

    test('Parses barcode with leading letter', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse('A123456');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));

      final result2 = parser.parse('Z123456 Test Item');
      expect(result2, isA<Success>());
      expect(result2.value, equals('123456'));
    });

    test('Parses barcode with leading space', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(' 123456');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Parses barcode with trailing letter', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse('123456A');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Test parsing barcode between other tokens.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'123456 Test Item $123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Test parsing barcode at the end.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'Article 30546706');
      expect(result, isA<Success>());
      expect(result.value, equals('30546706'));
    });

    test('Test parsing barcode at the end with price before.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'Test Item $123.45 123456');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Test parsing barcode in the middle.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'Test Item 123456 $123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Test parsing barcode with other items.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'008080076 TESTTEST $14.49');
      expect(result, isA<Success>());
      expect(result.value, equals('008080076'));
    });

    test('Test parsing barcode by itself.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'008080076');
      expect(result, isA<Success>());
      expect(result.value, equals('008080076'));
    });

    test('Should not parse phone numbers.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'123-456-7890');
      expect(result, isA<Failure>());
    });

    test('Should not parse decimals.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'123.45000');
      expect(result, isA<Failure>());
    });
  });
}
