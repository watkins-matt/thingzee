// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_linalg/linalg.dart';

class RecognizedTextMergeStrategy {
  String joinTextElementsAlt(List<TextElement> elements) {
    if (elements.isEmpty) return '';

    StringBuffer currentLine = StringBuffer(elements.first.text);
    TextElement previousElement = elements.first;

    for (int i = 1; i < elements.length; i++) {
      final currentElement = elements[i];
      final lastCharOfPrevious = previousElement.text.isNotEmpty
          ? previousElement.text.substring(previousElement.text.length - 1)
          : '';
      final firstCharOfCurrent =
          currentElement.text.isNotEmpty ? currentElement.text.substring(0, 1) : '';

      if (shouldAddSpace(lastCharOfPrevious, firstCharOfCurrent)) {
        currentLine.write(' ');
      }

      currentLine.write(currentElement.text);
      previousElement = currentElement;
    }

    return currentLine.toString().trim();
  }

  bool shouldAddSpace(String lastChar, String firstChar) {
    // Add space for lowercase to uppercase transition
    if (RegExp(r'[a-z]').hasMatch(lastChar) && RegExp(r'[A-Z]').hasMatch(firstChar)) {
      return true;
    }

    // Add space for number/symbol to letter transition
    if (!RegExp(r'[a-zA-Z]').hasMatch(lastChar) && RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
      return true;
    }

    // return false;
    return true;
  }

  static void logComparison(
      List<TextElement> originalElements, List<TextElement> normalizedElements) {
    int maxLength = max(originalElements.length, normalizedElements.length);

    for (int i = 0; i < maxLength; i++) {
      // Get the original and normalized elements, handling cases where lists have different lengths
      TextElement? original = i < originalElements.length ? originalElements[i] : null;
      TextElement? normalized = i < normalizedElements.length ? normalizedElements[i] : null;

      // Print details side by side
      print('Element $i Comparison:');
      print('  Original ${_elementDetails(original, false)}');
      print('  Normalized ${_elementDetails(normalized, true)}');
      print('-----------------------------------');
    }
  }

  static void logTextBlocks(List<TextBlock> blocks) {
    for (int blockIdx = 0; blockIdx < blocks.length; blockIdx++) {
      final block = blocks[blockIdx];
      print('TextBlock $blockIdx: ${block.text}');
      print('  Bounding Box: ${block.boundingBox}');
      print('  Recognized Languages: ${block.recognizedLanguages.join(", ")}');
      print('  Corner Points: ${block.cornerPoints.map((p) => '[${p.x}, ${p.y}]').join(", ")}');

      for (int lineIdx = 0; lineIdx < block.lines.length; lineIdx++) {
        final line = block.lines[lineIdx];
        print('  TextLine $lineIdx: ${line.text}');
        print('    Bounding Box: ${line.boundingBox}');
        print('    Recognized Languages: ${line.recognizedLanguages.join(", ")}');
        print('    Corner Points: ${line.cornerPoints.map((p) => '[${p.x}, ${p.y}]').join(", ")}');

        for (int elementIdx = 0; elementIdx < line.elements.length; elementIdx++) {
          final element = line.elements[elementIdx];
          print('    TextElement $elementIdx: ${element.text}');
          print('      Bounding Box: ${element.boundingBox}');
          print('      Recognized Languages: ${element.recognizedLanguages.join(", ")}');
          print(
              '      Corner Points: ${element.cornerPoints.map((p) => '[${p.x}, ${p.y}]').join(", ")}');
          print('      Confidence: ${element.confidence}');
        }
      }
    }
  }

  static void logTextElements(List<TextElement> elements, String stage) {
    for (int idx = 0; idx < elements.length; idx++) {
      final element = elements[idx];
      print('[$stage] TextElement $idx: ${element.text}');
      print('  Bounding Box: ${element.boundingBox}');
      // print('  Recognized Languages: ${element.recognizedLanguages.join(", ")}');
      print('  Corner Points: ${element.cornerPoints.map((p) => '[${p.x}, ${p.y}]').join(", ")}');
      // print('  Confidence: ${element.confidence}');
      print('  Angle: ${element.angle}');
    }
  }

  static List<String> processTextRecognitionResult(RecognizedText recognizedText, Size size) {
    // Extract and log original TextElements
    var originalElements = _extractTextElements(recognizedText);

    // Figure out the skew
    double averageSkew = _calculateAverageSkew(originalElements);

    // Calculate image center
    var imageCenter = Point<double>(size.width / 2, size.height / 2);

    // Rotate all the elements by the average skew
    var rotatedElements = _applyRotationToElements(originalElements, averageSkew, imageCenter);

    // Calculate the average height
    double averageHeight =
        rotatedElements.fold(0, (sum, element) => sum + element.boundingBox.height.round()) /
            rotatedElements.length;

    // Go through all of the elements and get a list of all the top edges
    // averaged together
    final tops = _averageTopEdges(rotatedElements, averageHeight);

    // Align every element to one of the top edges
    List<TextElement> alignedElements = _alignElementsToTops(rotatedElements, tops);

    //
    _sortTextElements(alignedElements);
    final groupedElements = _groupElementsByTopEdge(alignedElements);

    // Join the text elements in each group
    List<String> joinedTexts = _joinTextElements(groupedElements);
    return joinedTexts;
  }

  static List<Point<int>> _adjustToBoundingBox(Rect boundingBox) {
    return [
      Point(boundingBox.left.round(), boundingBox.top.round()),
      Point(boundingBox.right.round(), boundingBox.top.round()),
      Point(boundingBox.right.round(), boundingBox.bottom.round()),
      Point(boundingBox.left.round(), boundingBox.bottom.round()),
    ];
  }

  static List<TextElement> _alignElementsToTops(
      List<TextElement> elements, List<int> averagedTops) {
    return elements.map((element) {
      // Find the closest y top value
      int closestTop = averagedTops.reduce((closest, top) =>
          (closest - element.boundingBox.top).abs() < (top - element.boundingBox.top).abs()
              ? closest
              : top);

      // Update the corner points with the new y position for top corners
      List<Point<int>> updatedCornerPoints = element.cornerPoints.map((point) {
        bool isTopPoint = point.y == element.boundingBox.top.round();
        return isTopPoint ? Point(point.x, closestTop.round()) : point;
      }).toList();

      // Calculate new bounding box based on updated corner points
      final minX = updatedCornerPoints.map((p) => p.x).reduce(min);
      final minY = updatedCornerPoints.map((p) => p.y).reduce(min);
      final maxX = updatedCornerPoints.map((p) => p.x).reduce(max);
      final maxY = updatedCornerPoints.map((p) => p.y).reduce(max);
      Rect newBoundingBox = Rect.fromLTRB(
        minX.toDouble(),
        minY.toDouble(),
        maxX.toDouble(),
        maxY.toDouble(),
      ).round(); // Round the bounding box to ensure it aligns with the corner points

      // Return a new TextElement with the updated bounding box and corner points
      return TextElement(
        text: element.text,
        cornerPoints: updatedCornerPoints,
        symbols: element.symbols,
        recognizedLanguages: element.recognizedLanguages,
        confidence: element.confidence,
        boundingBox: newBoundingBox,
        angle: 0, // The angle is now effectively 0 after rotation
      );
    }).toList();
  }

  static List<TextElement> _applyRotationToElements(
      List<TextElement> elements, double skewAngle, Point<double> imageCenter) {
    // Convert degrees to radians for rotation
    final radians = -skewAngle * (pi / 180.0);

    // Rotation matrix for the given angle
    final rotationMatrix = Matrix.fromList([
      [cos(radians), -sin(radians)],
      [sin(radians), cos(radians)],
    ]);

    return elements.map((element) {
      // Convert the corner points to a list of column Vectors, translating to origin for rotation
      final columnVectors = element.cornerPoints.map((point) {
        return Vector.fromList([
          point.x.toDouble() - imageCenter.x,
          point.y.toDouble() - imageCenter.y,
        ]);
      }).toList();

      // Create a matrix from the column vectors representing the corner points
      final pointsMatrix = Matrix.fromColumns(columnVectors);

      // Apply rotation to the corner points
      final rotatedPointsMatrix = rotationMatrix * pointsMatrix;

      // Translate the points back to their original position
      final rotatedTranslatedPoints = rotatedPointsMatrix.columns.map((vector) {
        return Vector.fromList([
          vector[0] + imageCenter.x,
          vector[1] + imageCenter.y,
        ]);
      }).toList();

      // Compute the axis-aligned bounding box from the rotated points
      final rotatedBoundingBox = _computeBoundingBox(rotatedTranslatedPoints).round();

      // Adjust the corner points to match the axis-aligned bounding box
      final rotatedCornerPoints = _adjustToBoundingBox(rotatedBoundingBox);

      // Create and return the new text element with the updated corner points and bounding box
      return TextElement(
        text: element.text,
        symbols: element.symbols,
        recognizedLanguages: element.recognizedLanguages,
        confidence: element.confidence,
        cornerPoints: rotatedCornerPoints,
        boundingBox: rotatedBoundingBox,
        angle: 0, // The angle is now effectively 0 after rotation
      );
    }).toList();
  }

  static List<int> _averageTopEdges(List<TextElement> elements, double averageHeight) {
    List<double> topEdges = elements.map((e) => e.boundingBox.top).toList();
    topEdges.sort();

    List<int> averagedTops = [];
    double sum = 0;
    int count = 0;

    for (int i = 0; i < topEdges.length; i++) {
      sum += topEdges[i];
      count++;

      bool isLastElement = i == topEdges.length - 1;
      double nextElementDiff = isLastElement ? double.infinity : (topEdges[i + 1] - topEdges[i]);
      double averageDiff = sum / count;

      if (nextElementDiff > averageHeight * 0.3 || isLastElement) {
        averagedTops.add(averageDiff.round());
        sum = 0;
        count = 0;
      }
    }

    return averagedTops;
  }

  static double _calculateAverageSkew(List<TextElement> elements) {
    var angles = elements
        .where((element) => element.angle != null)
        .map((element) => element.angle!)
        .toList();

    if (angles.isEmpty) {
      return 0; // Return 0 if no elements have an angle to avoid division by zero
    }

    double sumOfAngles = angles.reduce((sum, angle) => sum + angle);
    return sumOfAngles / angles.length;
  }

  static Rect _computeBoundingBox(List<Vector> points) {
    final minX = points.map((v) => v[0]).reduce(min);
    final maxX = points.map((v) => v[0]).reduce(max);
    final minY = points.map((v) => v[1]).reduce(min);
    final maxY = points.map((v) => v[1]).reduce(max);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // Helper function to format TextElement details
  static String _elementDetails(TextElement? element, bool normalized) {
    if (element == null) return 'N/A';
    var normalizedStr = normalized ? 'Normalized' : ' ';

    return 'Text: ${element.text}\n'
        '    BoundingBox: ${element.boundingBox}\n'
        '   $normalizedStr Corner Points: ${element.cornerPoints.map((p) => '[${p.x}, ${p.y}]').join(", ")}\n'
        '    Aspect Ratio: ${element.boundingBox.width / element.boundingBox.height}\n'
        '    Height: ${element.boundingBox.height}\n'
        '    Width: ${element.boundingBox.width}\n'
        '    Angle: ${element.angle}';
  }

  static List<TextElement> _extractTextElements(RecognizedText recognizedText) {
    List<TextElement> textElements = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        textElements.addAll(line.elements);
      }
    }
    return textElements;
  }

  static Map<int, List<TextElement>> _groupElementsByTopEdge(List<TextElement> elements) {
    final Map<int, List<TextElement>> groupedElements = {};

    for (final element in elements) {
      int topEdge = element.cornerPoints.first.y; // Assuming the first point is the top-left
      if (!groupedElements.containsKey(topEdge)) {
        groupedElements[topEdge] = [];
      }
      groupedElements[topEdge]!.add(element);
    }

    // Ensure each group is sorted by the x value of the top-left corner point
    for (final group in groupedElements.values) {
      _sortTextElements(group);
    }

    return groupedElements;
  }

  static List<String> _joinTextElements(Map<int, List<TextElement>> groupedElements) {
    List<String> joinedTexts = [];

    // Sort the keys (top edges) to process rows in the correct vertical order
    List<int> sortedKeys = groupedElements.keys.toList()..sort();

    for (final key in sortedKeys) {
      String joinedText = groupedElements[key]!.map((element) => element.text).join(' ');
      joinedTexts.add(joinedText);
    }

    return joinedTexts;
  }

  static void _sortTextElements(List<TextElement> elements) {
    elements.sort((t1, t2) {
      int compareTop = t1.cornerPoints.first.y.compareTo(t2.cornerPoints.first.y);
      if (compareTop != 0) return compareTop;
      return t1.cornerPoints.first.x.compareTo(t2.cornerPoints.first.x);
    });
  }
}

extension on Rect {
  /// Rounds the coordinates of the bounding box to the nearest integer.
  Rect round() {
    return Rect.fromLTRB(
      left.roundToDouble(),
      top.roundToDouble(),
      right.roundToDouble(),
      bottom.roundToDouble(),
    );
  }
}
