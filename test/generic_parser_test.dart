import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:thingzee/pages/receipt_scanner/parser/generic_receipt_parser.dart';

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
      final result = parser.parse('123ABC');
      expect(result, isA<Failure>());
    });

    test('Returns the correct barcode for valid input', () {
      final parser = barcodeParser();
      final result = parser.parse('123456');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });

    test('Corrects numeric sequence with letter substitutions', () {
      final parser = barcodeParser();
      final result = parser.parse('O123D123');
      expect(result, isA<Success>());
      expect(result.value, equals('01230123'));
    });

    test('Removes whitespace from the input', () {
      final parser = barcodeParser();
      final result = parser.parse(' 1 2 3 4 5 6 ');
      expect(result, isA<Success>());
      expect(result.value, equals('123456'));
    });
  });

  group('skipToItemTextParser tests', () {
    test('Linter for skipToItemTextParser', () {
      final parser = skipToItemTextParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing item text between other tokens.', () {
      final parser = skipToItemTextParser();
      final result = parser.parse(r'123456 Test Item $123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('Test Item'));
    });
  });

  group('Test parsing prices', () {
    final parser = priceParser();

    test('Linter for priceParser', () {
      expect(linter(parser), isEmpty);
    });

    test('With dollar sign and exact format', () {
      var result = parser.parse(r'$123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('123.45'));
    });

    test('With spaces and dollar sign', () {
      var result = parser.parse(r' $ 2 34.56 ');
      expect(result, isA<Success>());
      expect(result.value, equals('234.56'));
    });

    test('Without dollar sign, with spaces around decimal', () {
      var result = parser.parse(r'234 . 56');
      expect(result, isA<Success>());
      expect(result.value, equals('234.56'));
    });

    test('Single digit before decimal', () {
      var result = parser.parse(r'$9.99');
      expect(result, isA<Success>());
      expect(result.value, equals('9.99'));
    });

    test('Without decimal place', () {
      var result = parser.parse(r'$1234 ');
      expect(result, isA<Success>());
      expect(result.value, equals('1234'));
    });

    test('With spaces, without dollar sign or decimal', () {
      var result = parser.parse(r' 5678 ');
      expect(result, isA<Failure>());
    });

    test('With leading and trailing spaces, dollar sign, and decimal', () {
      var result = parser.parse(r' $ 12 34.5 6 ');
      expect(result, isA<Success>());
      expect(result.value, equals('1234.56'));
    });

    test('Decimal without leading digits', () {
      var result = parser.parse(r'$.99');
      expect(result, isA<Success>());
      expect(result.value, equals('0.99'));
    });

    test('Negative number (should fail)', () {
      var result = parser.parse(r'-$123.45');
      expect(result, isA<Failure>());
    });

    test('Without dollar sign, large number with spaces', () {
      var result = parser.parse(r' 1 2 3 4 5 . 6 7 ');
      expect(result, isA<Success>());
      expect(result.value, equals('12345.67'));
    });
  });

  group('skipToPriceParser', () {
    test('Linter for skipToPriceParser', () {
      final parser = skipToPriceParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing price between other tokens.', () {
      final parser = skipToPriceParser();
      final result = parser.parse(r'123456 Test Item $123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('123.45'));
    });

    test('Test parsing price between other tokens with spaces.', () {
      final parser = skipToPriceParser();
      final result = parser.parse(r'  123 456  Test Item  $  12 3.4 5  ');
      expect(result, isA<Success>());
      expect(result.value, equals('123.45'));
    });
  });

  group('itemTextParser tests', () {
    test('Linter for itemTextParser', () {
      final parser = itemTextParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing item text.', () {
      final parser = itemTextParser();
      final result = parser.parse(r'Test Item 12');
      expect(result, isA<Success>());
      expect(result.value, equals('Test Item 12'));
    });
  });

  group('skipToBarcodeParser tests', () {
    test('Linter for skipToBarcodeParser', () {
      final parser = skipToBarcodeParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing barcode between other tokens.', () {
      final parser = skipToBarcodeParser();
      final result = parser.parse(r'123456 Test Item $123.45');
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

  group('quantityParser tests', () {
    test('Linter for quantityParser', () {
      final parser = quantityParser();
      expect(linter(parser), isEmpty);
    });

    test('Match one digit surrounded by whitespace', () {
      final parser = quantityParser();
      final result = parser.parse(' 1 ');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    test('Match two digits surrounded by whitespace', () {
      final parser = quantityParser();
      final result = parser.parse(' 12 ');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });

    test('Match one digit without whitespace', () {
      final parser = quantityParser();
      final result = parser.parse('1');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    test('Match two digits without whitespace', () {
      final parser = quantityParser();
      final result = parser.parse('12');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });

    test('Match one digit with leading whitespace', () {
      final parser = quantityParser();
      final result = parser.parse(' 1');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    test('Match two digits with leading whitespace', () {
      final parser = quantityParser();
      final result = parser.parse(' 12');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });

    test('Match one digit with trailing whitespace', () {
      final parser = quantityParser();
      final result = parser.parse('1 ');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    test('Match two digits with trailing whitespace', () {
      final parser = quantityParser();
      final result = parser.parse('12  ');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });

    test('Match one digit with leading and trailing whitespace', () {
      final parser = quantityParser();
      final result = parser.parse(' 1 ');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    test('Match two digits with leading and trailing whitespace', () {
      final parser = quantityParser();
      final result = parser.parse(' 12 ');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });

    test('Match one digit with multiple whitespace characters', () {
      final parser = quantityParser();
      final result = parser.parse(' 1 ');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    // test('Fail to match three digits', () {
    //   final parser = quantityParser();
    //   final result = parser.parse(' 123 ');
    //   expect(result, isA<Failure>());
    // });

    test('Fail to match non-digit input', () {
      final parser = quantityParser();
      final result = parser.parse(' ABC ');
      expect(result, isA<Failure>());
    });
  });

  group('skipToQuantityParser tests', () {
    test('Linter for skipToQuantityParser', () {
      final parser = skipToQuantityParser();
      expect(linter(parser), isEmpty);
    });

    // test('Test parsing quantity between other tokens.', () {
    //   final parser = skipToQuantityParser();
    //   var result = parser.parse(r'123456 Test Item $123.45  99 ');
    //   expect(result, isA<Success>());
    //   expect(result.value, equals('99'));

    //   result = parser.parse(r'98 123456 Test Item $123.45');
    //   expect(result, isA<Success>());
    //   expect(result.value, equals('98'));

    //   result = parser.parse(r'123456 Test Item 97 @ $123.45');
    //   expect(result, isA<Success>());
    //   expect(result.value, equals('97'));
    // });

    test('Test parsing quantity with trailing whitespace.', () {
      final parser = skipToQuantityParser();
      final result = parser.parse(r'12  ');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });

    test('Test parsing quantity with non-digit input.', () {
      final parser = skipToQuantityParser();
      final result = parser.parse(r'  ABC  ');
      expect(result, isA<Failure>());
    });

    // test('Test parsing quantity with more than two digits.', () {
    //   final parser = skipToQuantityParser();
    //   final result = parser.parse(r'  123  ');
    //   expect(result, isA<Failure>());
    // });

    test('Test parsing quantity with single digit.', () {
      final parser = skipToQuantityParser();
      final result = parser.parse(r'  1  ');
      expect(result, isA<Success>());
      expect(result.value, equals('1'));
    });

    test('Test parsing quantity with two digits.', () {
      final parser = skipToQuantityParser();
      final result = parser.parse(r'  12  ');
      expect(result, isA<Success>());
      expect(result.value, equals('12'));
    });
  });
}
