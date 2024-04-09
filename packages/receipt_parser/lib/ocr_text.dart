import 'dart:math';

import 'package:fuzzy/bitap/bitap.dart';
import 'package:fuzzy/bitap/data/match_score.dart';
import 'package:fuzzy/fuzzy.dart';

class OcrLine {
  List<String> variations = [];

  OcrLine(String initial) {
    variations.add(initial);
  }

  String get text {
    if (variations.isEmpty) {
      return '';
    }

    if (variations.length == 1) {
      return variations[0];
    }

    // First pass
    int initialTargetLength = _determineTargetLength();
    List<String> initiallyFilteredVersions = _filterVersionsByLength(initialTargetLength);
    Map<int, String> initialVotes = _voteOnCharacters(initiallyFilteredVersions);

    // Correct excluded variations
    List<String> correctedVariations =
        _correctExcludedVersions(variations, initialVotes, initialTargetLength);

    // Second Pass after correction
    int revisedTargetLength =
        _determineTargetLength(correctedVariations); // Use corrected variations
    List<String> revisedFilteredVersions =
        _filterVersionsByLength(revisedTargetLength, correctedVariations);
    Map<int, String> finalVotes = _voteOnCharacters(revisedFilteredVersions);

    return finalVotes.values.join();
  }

  void add(String variation) {
    variations.add(variation);
  }

  @override
  String toString() => text;

  String _correctExcludedVersion(String variation, Map<int, String> votedCharacters) {
    StringBuffer correctedVersion = StringBuffer();
    int versionIndex = 0; // Index for iterating through the original variation

    for (int voteIndex = 0; voteIndex < votedCharacters.length; voteIndex++) {
      if (versionIndex >= variation.length) break; // Prevent index out of range

      String currentChar = variation[versionIndex];
      String? consensusChar = votedCharacters[voteIndex];

      if (consensusChar == null) continue; // No consensus for this position

      if (currentChar == consensusChar) {
        correctedVersion.write(currentChar); // Character matches consensus
        versionIndex++; // Move to next character in the original variation
      } else if (versionIndex + 1 < variation.length) {
        String nextChar = variation[versionIndex + 1];
        if (nextChar == consensusChar) {
          // Next character in variation matches consensus, current character is likely erroneous
          correctedVersion.write(consensusChar); // Align with consensus
          versionIndex += 2; // Skip erroneous character and move to character after next
          continue; // Skip further checks and continue with next iteration
        }
      }
      // If the current character doesn't match the consensus and cannot be skipped,
      // it's appended as is, and further corrections might be needed.
      correctedVersion.write(currentChar);
      versionIndex++; // Move to next character in the original variation
    }

    // Update the original variation list if the corrected variation matches the target length
    String correctedString = correctedVersion.toString();
    if (correctedString.length == votedCharacters.length) {
      int index = variations.indexOf(variation);
      if (index != -1) {
        variations[index] =
            correctedString; // Replace the erroneous variation with the corrected one
      }
    }

    return correctedString;
  }

  List<String> _correctExcludedVersions(
      List<String> allVersions, Map<int, String> initialVotes, int targetLength) {
    List<String> correctedVersions = allVersions.map((variation) {
      return variation.length != targetLength
          ? _correctExcludedVersion(variation, initialVotes)
          : variation;
    }).toList();

    return correctedVersions;
  }

  int _determineTargetLength([List<String>? variationsToConsider]) {
    List<String> consideredVariations = variationsToConsider ?? variations;
    Map<int, int> lengthVotes = {};
    for (final String variation in consideredVariations) {
      int length = variation.length;
      lengthVotes[length] = (lengthVotes[length] ?? 0) + 1;
    }

    int targetLength = lengthVotes.entries
        .reduce(
            (a, b) => a.value > b.value ? a : (a.value == b.value ? (a.key < b.key ? a : b) : b))
        .key;

    return targetLength;
  }

  List<String> _filterVersionsByLength(int targetLength, [List<String>? variationsToConsider]) {
    List<String> consideredVariations = variationsToConsider ?? variations;
    return consideredVariations.where((variation) => variation.length == targetLength).toList();
  }

  Map<int, String> _voteOnCharacters(List<String> filteredVersions) {
    Map<int, String> votedCharacters = {};

    for (int i = 0; i < filteredVersions[0].length; i++) {
      Map<String, int> charVotes = {};
      for (final String variation in filteredVersions) {
        String char = variation[i];
        charVotes[char] = (charVotes[char] ?? 0) + 1;
      }

      String winningChar = charVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      votedCharacters[i] = winningChar;
    }

    return votedCharacters;
  }
}

class OcrText {
  List<OcrLine> lines = [];

  OcrText([List<OcrLine>? lines]) {
    this.lines = lines ?? [];
  }

  OcrText.fromLines(List<String> lines) {
    this.lines = lines.map((line) => OcrLine(line)).toList();
  }

  OcrText.fromString(String text) {
    lines = text.split('\n').map((line) => OcrLine(line)).toList();
  }

  String get text => lines.map((line) => line.text).join('\n');

  (List<OcrLine>, int) findLongestConsecutiveMatch(OcrText other, {double threshold = 0.1}) {
    int n = lines.length;
    int m = other.lines.length;
    List<List<int>> dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    int maxLength = 0;
    int endPosThis = 0; // End position in this OcrText

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (fuzzyMatch(lines[i - 1], other.lines[j - 1]) <= threshold) {
          // Match threshold
          dp[i][j] = dp[i - 1][j - 1] + 1;
          if (dp[i][j] > maxLength) {
            maxLength = dp[i][j];
            endPosThis = i;
          }
        }
      }
    }

    if (maxLength == 0) {
      return ([], -1); // Return an empty list if there's no match
    }

    // Extract the longest consecutive matching sequence of OcrLine objects
    return (lines.sublist(endPosThis - maxLength, endPosThis), endPosThis - maxLength);
  }

  (int indexThis, int indexOther) findMergeIndices(OcrText other, [double threshold = 0.1]) {
    var (List<OcrLine> longestMatch, int indexThis) = findLongestConsecutiveMatch(other);

    if (longestMatch.isEmpty) {
      return (-1, -1); // Indicate no match was found
    }

    int matchLength = longestMatch.length;

    // Iterate through `other.lines` to find a matching sequence that aligns with the sequence from `indexThis`
    for (int startIndexOther = 0;
        startIndexOther <= other.lines.length - matchLength;
        startIndexOther++) {
      bool fullSequenceMatches = true;
      for (int offset = 0; offset < matchLength; offset++) {
        if (fuzzyMatch(lines[indexThis + offset], other.lines[startIndexOther + offset]) >=
            threshold) {
          fullSequenceMatches = false;
          break; // Sequence does not match, break and move to the next starting index in `other.lines`
        }
      }

      if (fullSequenceMatches) {
        // Found a matching sequence in `other`, return the starting indices
        return (indexThis, startIndexOther);
      }
    }

    // No matching sequence found in `other`
    return (-1, -1);
  }

  void merge(OcrText other, [double threshold = 0.1]) {
    var (indexThis, indexOther) = findMergeIndices(other, threshold);

    if (indexThis == -1 || indexOther == -1) {
      // If there's no overlap, simply append all lines from the other OcrText.
      lines.addAll(other.lines);
      return;
    }

    // Calculate the end indices of the overlapping sequence in both OcrText instances
    var (List<OcrLine> longestMatch, _) = findLongestConsecutiveMatch(other);
    int overlapLength = longestMatch.length;
    int endThis = indexThis + overlapLength;
    int endOther = indexOther + overlapLength;

    // Update versions of overlapping lines in the current OcrText
    for (int i = indexThis, j = indexOther; i < endThis && j < endOther; i++, j++) {
      lines[i].add(other.lines[j].text);
    }

    // Create a hashtable of all the existing lines
    Map<String, OcrLine> existingLines = {};
    for (int i = 0; i < lines.length; i++) {
      existingLines[lines[i].text] = lines[i];
    }

    int matchingRemainingLines = 0;
    int remainingLines = other.lines.length - endOther;

    // Iterate through the remaining lines to see if they are in the hashtable
    for (int i = endOther; i < other.lines.length; i++) {
      if (existingLines.containsKey(other.lines[i].text)) {
        matchingRemainingLines++;
      }
    }

    double matchPercent = matchingRemainingLines / remainingLines;
    if (matchPercent > 0.2) {
      return; // If more than 20% of the remaining lines match, don't append them
    }

    // Append non-overlapping lines from the other OcrText that come after the overlap
    for (int i = endOther; i < other.lines.length; i++) {
      lines.add(other.lines[i]);
    }
  }

  OcrText sublist(int start, [int? end]) {
    if (start == -1) {
      start = 0;
    }

    if (end == null || end == -1) {
      end = lines.length;
    }

    return OcrText(lines.sublist(start, end));
  }

  static double fuzzyMatch(OcrLine firstLine, OcrLine secondLine) {
    // Calculate the absolute difference in length between the two lines
    int lengthDifference = (firstLine.text.length - secondLine.text.length).abs();

    // If the difference is more than 20% of the length of the shorter line,
    // consider it a non-match.
    double lengthDifferenceThreshold = 0.1 * min(firstLine.text.length, secondLine.text.length);

    // Length difference exceeds the threshold
    if (lengthDifference > lengthDifferenceThreshold) {
      return 1; // Return the maximum score to indicate no match
    }

    FuzzyOptions defaultOptions = FuzzyOptions(
      location: 0,
      distance: 100,
      threshold: 0.6,
      isCaseSensitive: false,
      findAllMatches: false,
      maxPatternLength: 32,
      minMatchCharLength: min(firstLine.text.length, secondLine.text.length),
      shouldSort: true,
      tokenize: true,
      matchAllTokens: true,
      verbose: true,
      shouldNormalize: true,
    );

    Bitap bitap = Bitap(firstLine.text, options: defaultOptions);
    MatchScore matchScore = bitap.search(secondLine.text);

    return matchScore.score;
  }
}
