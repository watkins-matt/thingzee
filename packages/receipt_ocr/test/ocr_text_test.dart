import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_parser/parser/ocr_text.dart';

void main() {
  group('fuzzyMatch tests', () {
    test('Returns 0 for perfect match', () {
      final firstLine = OcrLine('Perfect match');
      final secondLine = OcrLine('Perfect match');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, equals(0));
    });

    test('Same string, but different line lengths', () {
      final firstLine = OcrLine('Imperfect match');
      final secondLine = OcrLine('Imperfect match with a typo');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, equals(1));
    });

    test('Returns 0 for empty lines', () {
      final firstLine = OcrLine('');
      final secondLine = OcrLine('');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, equals(0));
    });

    test('Different line lengths and different strings', () {
      final firstLine = OcrLine('Hello, world!');
      final secondLine = OcrLine('No match at all');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, equals(1));
    });

    test('Lines with a single substitution', () {
      final firstLine = OcrLine('Hello, world!');
      final secondLine = OcrLine('Hello, world?');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, lessThan(.1));
    });

    test('Lines with a single word different', () {
      final firstLine = OcrLine('Main match 1');
      final secondLine = OcrLine('Late match 1');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, greaterThan(.1));
    });

    test('Lines that are totally different', () {
      final firstLine = OcrLine('First Second Third');
      final secondLine = OcrLine('Fourth Fifth Sixth');

      final score = OcrText.fuzzyMatch(firstLine, secondLine);
      expect(score, greaterThan(.75));
    });
  });

  group('findLongestConsecutiveMatch tests', () {
    test('Identifies long sequence of matching lines', () {
      final ocrText1 = OcrText([
        for (var i = 1; i <= 5; i++) OcrLine('Intro line $i'),
        for (var i = 1; i <= 10; i++) OcrLine('Match $i'),
        for (var i = 1; i <= 5; i++) OcrLine('Outro line $i'),
      ]);

      final ocrText2 = OcrText([
        for (var i = 1; i <= 10; i++) OcrLine('Match $i'),
      ]);

      final (lcs, _) = ocrText1.findLongestConsecutiveMatch(ocrText2);

      expect(lcs.length, equals(10));
      expect(lcs.first.text, equals('Match 1'));
      expect(lcs.last.text, equals('Match 10'));
    });

    test('Finds the longest sequence among multiple matches', () {
      final ocrText1 = OcrText([
        for (var i = 1; i <= 3; i++) OcrLine('Early match $i'), // Shorter match sequence
        for (var i = 1; i <= 10; i++) OcrLine('Main match $i'), // The longest match sequence
        for (var i = 1; i <= 2; i++) OcrLine('Late match $i'), // Another shorter match sequence
      ]);

      final ocrText2 = OcrText([
        for (var i = 1; i <= 10; i++) OcrLine('Main match $i'),
      ]);

      final (lcs, _) = ocrText1.findLongestConsecutiveMatch(ocrText2);

      expect(lcs.length, equals(10));
      expect(lcs.first.text, startsWith('Main match'));
      expect(lcs.last.text, equals('Main match 10'));
    });

    test('Handles no matching sequences gracefully', () {
      final ocrText1 = OcrText([
        for (var i = 1; i <= 5; i++) OcrLine('Unique intro line $i'),
      ]);

      final ocrText2 = OcrText([
        for (var i = 1; i <= 5; i++) OcrLine('Different line $i'),
      ]);

      final (lcs, _) = ocrText1.findLongestConsecutiveMatch(ocrText2);
      expect(lcs.isEmpty, isTrue);
    });
  });

  group('findMergeIndices tests', () {
    test('Correctly identifies starting indices of matching sequences', () {
      var ocrText1 = OcrText([
        OcrLine('Line 1'),
        OcrLine('Line 2'), // Start of match
        OcrLine('Line 3'),
        OcrLine('Line 4'),
      ]);

      var ocrText2 = OcrText([
        OcrLine('Other Line 1'),
        OcrLine('Line 2'), // Start of match
        OcrLine('Line 3'),
      ]);

      var result = ocrText1.findMergeIndices(ocrText2);
      expect(result, equals((1, 1)));
    });

    test('Returns (-1, -1) when there are no matches', () {
      var ocrText1 = OcrText([
        OcrLine('Unique Line A'),
        OcrLine('Unique Line B'),
      ]);

      var ocrText2 = OcrText([
        OcrLine('Different Line 1'),
        OcrLine('Different Line 2'),
      ]);

      var result = ocrText1.findMergeIndices(ocrText2);
      expect(result, equals((-1, -1)));
    });

    test('Correctly identifies matches at different positions', () {
      var ocrText1 = OcrText([
        OcrLine('Intro Line'),
        OcrLine('Line A'), // Matching sequence starts here in ocrText1
        OcrLine('Line B'),
      ]);

      var ocrText2 = OcrText([
        OcrLine('Line A'), // Matching sequence starts here in ocrText2
        OcrLine('Line B'),
        OcrLine('Extra Line'),
      ]);

      var result = ocrText1.findMergeIndices(ocrText2);
      expect(result, equals((1, 0)));
    });
  });

  group('merge tests', () {
    test('Merge with overlapping lines updates versions and appends new lines correctly', () {
      var ocrText1 = OcrText([
        OcrLine('A'),
        OcrLine('B'),
        OcrLine('C'),
      ]);

      var ocrText2 = OcrText([
        OcrLine('B'), // Overlap
        OcrLine('C'), // Overlap
        OcrLine('D'), // New line to append
      ]);

      ocrText1.merge(ocrText2);

      // Expecting OcrText1 to have updated versions for B, C, and appended D
      expect(ocrText1.lines.length, equals(4)); // A, B, C, D
      expect(ocrText1.lines[1].variations, contains('B')); // Original and new version of B
      expect(ocrText1.lines[2].variations, contains('C')); // Original and new version of C
      expect(ocrText1.lines[3].text, equals('D')); // Appended D
    });

    test('Merge without overlap appends all lines from the other OcrText', () {
      var ocrText1 = OcrText([
        OcrLine('A'),
        OcrLine('B'),
      ]);

      var ocrText2 = OcrText([
        OcrLine('C'),
        OcrLine('D'),
      ]);

      ocrText1.merge(ocrText2);

      // Expecting OcrText1 to have A, B, C, D
      expect(ocrText1.lines.length, equals(4)); // A, B, C, D appended
    });

    test('Merge with partial match at different positions updates and appends correctly', () {
      var ocrText1 = OcrText([
        OcrLine('A'), // Unique
        OcrLine('B'), // Starting overlap
        OcrLine('C'), // Ending overlap
        OcrLine('D'), // Unique
      ]);

      var ocrText2 = OcrText([
        OcrLine('B'), // Overlap start
        OcrLine('C'), // Overlap end
        OcrLine('E'), // New line to append
        OcrLine('F'), // New line to append
      ]);

      ocrText1.merge(ocrText2);

      // Expecting OcrText1 to have updated versions for B, C, and appended E, F
      expect(ocrText1.lines.length, equals(6)); // A, B, C, D, E, F
      expect(ocrText1.lines[1].variations, contains('B')); // Original and new version of B
      expect(ocrText1.lines[2].variations, contains('C')); // Original and new version of C
      expect(ocrText1.lines[4].text, equals('E')); // Appended E
      expect(ocrText1.lines[5].text, equals('F')); // Appended F
    });

    test('Merge with no common lines appends all lines', () {
      var ocrText1 = OcrText([
        OcrLine('A'),
        OcrLine('B'),
      ]);

      var ocrText2 = OcrText([
        OcrLine('X'),
        OcrLine('Y'),
      ]);

      ocrText1.merge(ocrText2);

      // Expecting OcrText1 to now contain A, B, X, Y
      expect(ocrText1.lines.length, equals(4)); // A, B, X, Y appended
    });
  });
}
