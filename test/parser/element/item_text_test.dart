import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:thingzee/pages/receipt_scanner/parser/element/item_text.dart';

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
}
