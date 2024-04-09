import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:receipt_parser/parser/element/item_text.dart';
import 'package:test/test.dart';

void main() {
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

      final result2 = parser.parse(r'Test Item 123456 $123.45');
      expect(result2, isA<Success>());
      expect(result2.value, equals('Test Item'));

      final result3 = parser.parse(r'Test Item $123.45 123456');
      expect(result3, isA<Success>());
      expect(result3.value, equals('Test Item'));

      final result4 = parser.parse(r'123456 $123.45 Test Item');
      expect(result4, isA<Success>());
      expect(result4.value, equals('Test Item'));

      final result5 = parser.parse(r'123456 Test Item');
      expect(result5, isA<Success>());
      expect(result5.value, equals('Test Item'));
    });

    test('Test parsing item names with numbers in them.', () {
      final parser = skipToItemTextParser();
      final result = parser.parse(r'123456 T2 Item $123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('T2 Item'));
    });

    test('Test parsing where there is a letter in the barcode.', () {
      final parser = skipToItemTextParser();
      final result = parser.parse(r'123456A Test Item $123.45');
      expect(result, isA<Success>());
      expect(result.value, equals('Test Item'));

      final result2 = parser.parse(r'1E3456 Test Item $123.45');
      expect(result2, isA<Success>());
      expect(result2.value, equals('Test Item'));
    });

    test('Test parsing with item text the number with decimal', () {
      final parser = skipToItemTextParser();
      final result = parser.parse(r'Test Item .12');
      expect(result, isA<Success>());
      expect(result.value, equals('Test Item'));
    });
  });

  group('itemTextParser tests', () {
    test('Linter for itemTextParser', () {
      final parser = itemTextParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing item text.', () {
      final parser = itemTextParser();
      final result = parser.parse(r'Test Item T2 12');
      expect(result, isA<Success>());
      expect(result.value, equals('Test Item T2 12'));
    });
  });
}
