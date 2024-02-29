import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/price.dart';

void main() {
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
}
