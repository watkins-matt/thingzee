import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:receipt_parser/stores/target.dart';
import 'package:test/test.dart';

void main() {
  group('skipToTargetQuantityParser tests', () {
    test('Linter for skipToTargetQuantityParser', () {
      final parser = skipToTargetQuantityParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing with other text before', () {
      final parser = skipToTargetQuantityParser();
      final result = parser.parse(r'Some text before 1 @ $10.99 ea');
      expect(result, isA<Success>());
      expect(result.value, equals((quantity: 1, price: 10.99)));
    });

    test('Test parsing with surrounding text', () {
      final parser = skipToTargetQuantityParser();
      final result = parser.parse(r'1 @ $10.99 ea Some text after');
      expect(result, isA<Success>());
      expect(result.value, equals((quantity: 1, price: 10.99)));
    });
  });

  group('targetQuantityParser tests', () {
    test('Test parsing target quantity with valid input.', () {
      final parser = targetQuantityParser();
      final result = parser.parse(r'1 @ $10.99 ea');
      expect(result, isA<Success>());
      expect(result.value, equals((quantity: 1, price: 10.99)));
    });

    test('Test parsing with no whitespace', () {
      final parser = targetQuantityParser();
      final result = parser.parse(r'1@$10.99 ea');
      expect(result, isA<Success>());
      expect(result.value, equals((quantity: 1, price: 10.99)));
    });

    test('Test parsing target quantity with invalid input.', () {
      final parser = targetQuantityParser();
      final result = parser.parse(r'ABC @ $10.99 ea');
      expect(result, isA<Failure>());
    });
  });

  group('skipToTargetRegularPriceParser tests', () {
    test('Linter for skipToTargetRegularPriceParser', () {
      final parser = skipToTargetRegularPriceParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing with other text before', () {
      final parser = skipToTargetRegularPriceParser();
      final result = parser.parse(r'Some text before Regular Price $10.99 ea');
      expect(result, isA<Success>());
      expect(result.value, equals(10.99));
    });

    test('Test parsing with surrounding text', () {
      final parser = skipToTargetRegularPriceParser();
      final result = parser.parse(r'Regular Price $10.99 Some text after');
      expect(result, isA<Success>());
      expect(result.value, equals(10.99));
    });

    test('Test parsing with no whitespace', () {
      final parser = skipToTargetRegularPriceParser();
      final result = parser.parse(r'Regular Price$10.99');
      expect(result, isA<Success>());
      expect(result.value, equals(10.99));
    });
  });
  group('skipToTargetBottleDepositFeeParser tests', () {
    test('Linter for skipToTargetBottleDepositFeeParser', () {
      final parser = skipToTargetBottleDepositFeeParser();
      expect(linter(parser), isEmpty);
    });

    test('Test parsing with other text before', () {
      final parser = skipToTargetBottleDepositFeeParser();
      final result = parser.parse(r'Some text before Bottle Deposit Fee $0.50');
      expect(result, isA<Success>());
      expect(result.value, equals(0.50));
    });

    test('Test parsing with surrounding text', () {
      final parser = skipToTargetBottleDepositFeeParser();
      final result = parser.parse(r'Bottle Deposit Fee $0.50 Some text after');
      expect(result, isA<Success>());
      expect(result.value, equals(0.50));
    });

    test('Test parsing with no whitespace', () {
      final parser = skipToTargetBottleDepositFeeParser();
      final result = parser.parse(r'Bottle Deposit Fee$0.50');
      expect(result, isA<Success>());
      expect(result.value, equals(0.50));

      final result2 = parser.parse(r'BottleDepositFee$0.50');
      expect(result2, isA<Success>());
      expect(result2.value, equals(0.50));
    });
  });
}
