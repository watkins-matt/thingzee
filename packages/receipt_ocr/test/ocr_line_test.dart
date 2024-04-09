import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_parser/parser/ocr_text.dart';

void main() {
  group('OcrLine tests', () {
    test('Returns the correct text for a single version', () {
      final line = OcrLine('Hello, world!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with perfect match', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, world!');
      line.add('Hello, world!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with different characters', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, w0rld!');
      line.add('Hello, wor1d!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with different lengths', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, world');
      line.add('Hello, world!!');
      expect(line.text, equals('Hello, world'));
    });

    test('Returns the correct text for multiple versions with single substitution', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, world?');
      line.add('Hello, world!');
      line.add('Hello, world!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with single deletion', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, orld!');
      line.add('Hello, world!');
      line.add('Hello, world!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with single insertion', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, world!!');
      line.add('Hello, world!');
      line.add('Hello, world!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with multiple substitutions', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, wor1d!');
      line.add('Hello, w0rld!');
      line.add('Hello, world!');
      expect(line.text, equals('Hello, world!'));
    });

    test('Returns the correct text for multiple versions with multiple insertions', () {
      final line = OcrLine('Hello, world!');
      line.add('Hello, world!!');
      line.add('Hello, world!!');
      expect(line.text, equals('Hello, world!!'));
    });

    test('Correctly generates canonical form from uniform versions', () {
      var line = OcrLine('12345');
      line.add('12345');
      line.add('12345');

      expect(line.text, equals('12345'));
    });

    test('Determines target length and excludes longer erroneous version', () {
      var line = OcrLine('12345');
      line.add('12345');
      line.add('12345 ');

      // Expecting the space in the erroneous version to be ignored
      expect(line.text, equals('12345'));
    });

    test('Corrects excluded version by removing an erroneous character', () {
      var line = OcrLine('12345');
      line.add('1234 5'); // Erroneous space that should be removed

      expect(line.text, equals('12345'));
    });

    test('Integrates corrected excluded version into final votes', () {
      var line = OcrLine('ABCD');
      line.add('ABCE');
      line.add('A BCE'); // Erroneous space that should be removed

      expect(line.text, equals('ABCE'));
    });

    test('Handles tie in length votes by preferring shorter length', () {
      var line = OcrLine('123');
      line.add('1234'); // Longer version that should not dictate target length
      line.add('123');

      // Prefer the shorter length (3) as the target due to tie and exclude the longer version
      expect(line.text, equals('123'));
    });

    test('Processes complex scenario with multiple corrections', () {
      var line = OcrLine('12345');
      line.add('123 45'); // Space should be removed
      line.add('12  345'); // Space should be removed
      line.add('12345');

      // After correcting excluded versions, '123456' should be the consensus
      expect(line.text, equals('12345'));
    });
  });
}
