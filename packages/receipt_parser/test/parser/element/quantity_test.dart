import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:receipt_parser/parser/element/quantity.dart';
import 'package:test/test.dart';

void main() {
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
