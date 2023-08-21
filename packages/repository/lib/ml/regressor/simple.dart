import 'package:repository/ml/regressor/regressor.dart';

class SimpleLinearRegressor implements Regressor {
  late double _intercept;
  late double _slope;

  SimpleLinearRegressor(Map<double, double> dataPoints) {
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
    _intercept = yMean - _slope * xMean;
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
  String get type => 'Simple';

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
