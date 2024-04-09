import 'package:petitparser/petitparser.dart';
import 'package:receipt_parser/element/phone_number.dart';
import 'package:test/test.dart';

void main() {
  group('PhoneNumberParser', () {
    test('Should parse phone number without parentheses.', () {
      final parser = phoneNumberWithoutParenthesesParser();
      final result = parser.parse('123-456-7890');
      expect(result, isA<Success>());
      expect(result.value, '123-456-7890');
    });

    test('Should parse phone number with parentheses.', () {
      final parser = phoneNumberWithParenthesesParser();
      final result = parser.parse('(123) 456-7890');
      expect(result, isA<Success>());
      expect(result.value, '123-456-7890');
    });

    test('Should parse phone number with or without parentheses.', () {
      final parser = phoneNumberParser();
      final result1 = parser.parse('123-456-7890');
      final result2 = parser.parse('(123) 456-7890');
      expect(result1, isA<Success>());
      expect(result1.value, '123-456-7890');
      expect(result2, isA<Success>());
      expect(result2.value, '123-456-7890');
    });

    test('Should skip to phone number.', () {
      final parser = skipToPhoneNumberParser();
      final result = parser.parse('Some text before (123) 456-7890 Some text after');
      expect(result, isA<Success>());
      expect(result.value, '123-456-7890');

      final result2 = parser.parse('Some text before 123-456-7890 Some text after');
      expect(result2, isA<Success>());
      expect(result2.value, '123-456-7890');

      final result3 = parser.parse('Some text before 123-456-7890');
      expect(result3, isA<Success>());
      expect(result3.value, '123-456-7890');

      final result4 = parser.parse('123-456-7890 Some text after');
      expect(result4, isA<Success>());
      expect(result4.value, '123-456-7890');
    });
  });
}
