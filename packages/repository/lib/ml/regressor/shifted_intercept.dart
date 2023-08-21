import 'package:repository/ml/regressor/regressor.dart';

class ShiftedInterceptLinearRegressor implements Regressor {
  late double _intercept;
  late double _slope;

  ShiftedInterceptLinearRegressor(Map<int, double> dataPoints) {
    final xValues = dataPoints.keys.toList();
    final yValues = dataPoints.values.toList();

    // Calculate the means of x and y
    final xMean = xValues.reduce((a, b) => a + b) / xValues.length;
    final yMean = yValues.reduce((a, b) => a + b) / yValues.length;

    // Calculate slope (m) and intercept (c) for y = mx + c
    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < xValues.length; i++) {
      numerator += (xValues[i] - xMean) * (yValues[i] - yMean);
      denominator += (xValues[i] - xMean) * (xValues[i] - xMean);
    }

    _slope = numerator / denominator;

    // Find point with maximum x value
    final xMax = xValues.reduce((current, next) => current > next ? current : next);
    final yMax = dataPoints[xMax]!;

    // Adjust intercept so line passes through (xMax, yMax)
    _intercept = yMax - _slope * xMax;
  }

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  double get slope => _slope;

  @override
  String get type => 'ShiftedIntercept';

  @override
  int get xIntercept {
    return (-_intercept / _slope).round();
  }

  @override
  double predict(int x) {
    return _slope * x + _intercept;
  }
}
