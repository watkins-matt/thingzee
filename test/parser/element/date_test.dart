import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/date.dart';

void main() {
  group('dateParser tests', () {
    test('Test parsing date in MM/DD/YYYY format', () {
      final parser = dateParser();
      final result = parser.parse('12/31/2022');
      expect(result, isA<Success>());
      expect(result.value, equals('2022-12-31'));
    });

    test('Test parsing date in YYYY-MM-DD format', () {
      final parser = dateParser();
      final result = parser.parse('2022-12-31');
      expect(result, isA<Success>());
      expect(result.value, equals('2022-12-31'));
    });

    test('Test parsing invalid date', () {
      final parser = dateParser();
      final result = parser.parse('2022/12/31');
      expect(result, isA<Failure>());
    });
  });

  group('dateWithDashesParser tests', () {
    test('Test parsing date in YYYY-MM-DD format', () {
      final parser = dateWithDashesParser();
      final result = parser.parse('2022-12-31');
      expect(result, isA<Success>());
      expect(result.value, equals('2022-12-31'));
    });

    test('Test parsing invalid date', () {
      final parser = dateWithDashesParser();
      final result = parser.parse('12/31/2022');
      expect(result, isA<Failure>());
    });
  });

  group('dateWithSlashesParser tests', () {
    test('Test parsing date in MM/DD/YYYY format', () {
      final parser = dateWithSlashesParser();
      final result = parser.parse('12/31/2022');
      expect(result, isA<Success>());
      expect(result.value, equals('12/31/2022'));
    });

    test('Test parsing invalid date', () {
      final parser = dateWithSlashesParser();
      final result = parser.parse('2022-12-31');
      expect(result, isA<Failure>());
    });
  });

  group('normalizeDate tests', () {
    test('Test normalizing date in MM/DD/YYYY format', () {
      final result = normalizeDate('12/31/2022');
      expect(result, equals('2022-12-31'));
    });

    test('Test normalizing date in YYYY-MM-DD format', () {
      final result = normalizeDate('2022-12-31');
      expect(result, equals('2022-12-31'));
    });

    test('Test normalizing invalid date', () {
      final result = normalizeDate('2022/12/31');
      expect(result, equals('2022-12-31'));
    });
  });

  group('skipToDateParser tests', () {
    test('Test skipping characters and parsing date in MM/DD/YYYY format', () {
      final parser = skipToDateParser();
      final result = parser.parse('Some text before 12/31/2022');
      expect(result, isA<Success>());
      expect(result.value, equals('2022-12-31'));
    });

    test('Test skipping characters and parsing date in YYYY-MM-DD format', () {
      final parser = skipToDateParser();
      final result = parser.parse('Some text before 2022-12-31');
      expect(result, isA<Success>());
      expect(result.value, equals('2022-12-31'));
    });

    test('Test skipping characters and parsing invalid date', () {
      final parser = skipToDateParser();
      final result = parser.parse('Some text before 2022/12/31');
      expect(result, isA<Failure>());
    });
  });

  group('normalizeDate tests', () {
    test('Returns same sequence for valid "YYYY-MM-DD" format', () {
      const sequence = '2022-12-31';
      final result = normalizeDate(sequence);
      expect(result, equals(sequence));
    });

    test('Converts "MM/DD/YYYY" format to "YYYY-MM-DD"', () {
      const sequence = '12/31/2022';
      const expected = '2022-12-31';
      final result = normalizeDate(sequence);
      expect(result, equals(expected));
    });

    test('Returns same sequence for incomplete format', () {
      const sequence = '12/31';
      final result = normalizeDate(sequence);
      expect(result, equals(sequence));
    });
  });
}
