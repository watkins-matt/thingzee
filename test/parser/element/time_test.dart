import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/time.dart';

void main() {
  group('skipToTimeParser tests', () {
    test('Test parsing with other text before', () {
      final parser = skipToTimeParser();
      final result = parser.parse('Some text before 12:34 PM');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34 PM'));
    });

    test('Test parsing with surrounding text', () {
      final parser = skipToTimeParser();
      final result = parser.parse('12:34 PM Some text after');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34 PM'));
    });

    test('Test parsing with no whitespace', () {
      final parser = skipToTimeParser();
      final result = parser.parse('12:34PM');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34PM'));
    });
  });

  group('timeParser tests', () {
    test('Test parsing time with valid input.', () {
      final parser = timeParser();
      final result = parser.parse('12:34 PM');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34 PM'));
    });

    test('Test parsing time with no seconds', () {
      final parser = timeParser();
      final result = parser.parse('12:34 PM');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34 PM'));
    });

    test('Test parsing time with optional seconds', () {
      final parser = timeParser();
      final result = parser.parse('12:34:56 PM');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34:56 PM'));
    });

    test('Test parsing time with no AM/PM', () {
      final parser = timeParser();
      final result = parser.parse('12:34');
      expect(result, isA<Success>());
      expect(result.value, equals('12:34'));
    });

    test('Test parsing time with invalid input.', () {
      final parser = timeParser();
      final result = parser.parse('ABC');
      expect(result, isA<Failure>());
    });
  });

  group('TimeConversion tests', () {
    test('Test converting time to 24-hour format', () {
      expect('12:34 PM'.to24HourTime(), equals('12:34'));
      expect('12:34 AM'.to24HourTime(), equals('00:34'));
      expect('01:23 PM'.to24HourTime(), equals('13:23'));
      expect('01:23 AM'.to24HourTime(), equals('01:23'));
    });

    test('Test converting time to AM/PM format', () {
      expect('12:34'.toAmPmTime(), equals('12:34 PM'));
      expect('00:34'.toAmPmTime(), equals('12:34 AM'));
      expect('13:23'.toAmPmTime(), equals('01:23 PM'));
      expect('01:23'.toAmPmTime(), equals('01:23 AM'));
    });

    test('Test converting invalid time format', () {
      expect('ABC'.to24HourTime(), equals('Invalid Time Format'));
      expect('ABC'.toAmPmTime(), equals('Invalid Time Format'));
    });
  });
}
