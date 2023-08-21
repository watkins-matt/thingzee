import 'package:repository/ml/regressor/regressor.dart';

class SpecificPointRegressor implements Regressor {
  late double _intercept;
  late double _slope;
  final int firstIndex;
  final int lastIndex;

  SpecificPointRegressor(this.firstIndex, this.lastIndex, Map<double, double> dataPoints) {
    final xValues = dataPoints.keys.toList();
    final yValues = dataPoints.values.toList();

    if (firstIndex < 0 ||
        firstIndex >= xValues.length ||
        lastIndex < 0 ||
        lastIndex >= xValues.length) {
      throw ArgumentError('Indices are out of bounds for the provided data points.');
    }

    if (firstIndex == 0 && lastIndex == xValues.length - 1 && xValues.length < 2) {
      throw ArgumentError(
          'Data points must contain at least two entries for the PointBasedRegressor using the first and last points.');
    } else if (xValues.length < 3) {
      throw ArgumentError(
          'Data points must contain at least three entries for the PointBasedRegressor.');
    }

    // Get the values based on the provided indices
    final x1 = xValues[firstIndex].toDouble();
    final y1 = yValues[firstIndex];
    final x2 = xValues[lastIndex].toDouble();
    final y2 = yValues[lastIndex];

    // Calculate slope (m) for y = mx + c using the formula: m = (y2 - y1) / (x2 - x1)
    _slope = (y2 - y1) / (x2 - x1);

    // Calculate the intercept (c) using the formula: c = y1 - m * x1
    _intercept = y1 - _slope * x1;
  }

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  bool get hasYIntercept => true;

  @override
  double get slope => _slope;

  @override
  String get type => 'SpecificPoint[$firstIndex:$lastIndex]';

  @override
  double get xIntercept {
    return -_intercept / _slope;
  }

  @override
  double get yIntercept => _intercept;

  @override
  double predict(double x) {
    return _slope * x + _intercept;
  }
}
