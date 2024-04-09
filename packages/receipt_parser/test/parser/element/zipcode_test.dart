import 'package:petitparser/petitparser.dart';
import 'package:receipt_parser/element/zipcode.dart';
import 'package:test/test.dart';

void main() {
  group('skipToZipCodeParser tests', () {
    test('Test parsing with other text before', () {
      final parser = skipToZipCodeParser();
      final result = parser.parse('Some text before 12345');
      expect(result, isA<Success>());
      expect(result.value, equals('12345'));
    });

    test('Test parsing with surrounding text', () {
      final parser = skipToZipCodeParser();
      final result = parser.parse('12345 Some text after');
      expect(result, isA<Success>());
      expect(result.value, equals('12345'));
    });

    test('Test parsing with no whitespace', () {
      final parser = skipToZipCodeParser();
      final result = parser.parse('12345SomeTextAfter');
      expect(result, isA<Failure>());
    });
  });

  group('zipCodeParser tests', () {
    test('Test parsing basic ZIP code', () {
      final parser = zipCodeParser();
      final result = parser.parse('12345');
      expect(result, isA<Success>());
      expect(result.value, equals('12345'));
    });

    test('Test parsing ZIP+4 code', () {
      final parser = zipCodeParser();
      final result = parser.parse('12345-6789');
      expect(result, isA<Success>());
      expect(result.value, equals('12345-6789'));
    });

    test('Test parsing ZIP+4 code with no hyphen', () {
      final parser = zipCodeParser();
      final result = parser.parse('123456789');
      expect(result, isA<Failure>());
    });

    test('Test parsing invalid ZIP code', () {
      final parser = zipCodeParser();
      final result = parser.parse('ABCDE');
      expect(result, isA<Failure>());
    });
  });
}
