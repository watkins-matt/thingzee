import 'package:repository/ml/regressor/regressor.dart';

class WeightedLeastSquaresLinearRegressor implements Regressor {
  late double _intercept;
  late double _slope;

  WeightedLeastSquaresLinearRegressor(Map<int, double> dataPoints) {
    final xValues = dataPoints.keys.toList();
    final yValues = dataPoints.values.toList();

    // Create weights that decrease linearly
    final weights = List<double>.generate(xValues.length, (i) => (xValues.length - i).toDouble());

    // Calculate the weighted means of x and y
    final xMean =
        xValues.asMap().entries.map((e) => e.value * weights[e.key]).reduce((a, b) => a + b) /
            weights.reduce((a, b) => a + b);
    final yMean =
        yValues.asMap().entries.map((e) => e.value * weights[e.key]).reduce((a, b) => a + b) /
            weights.reduce((a, b) => a + b);

    // Calculate slope (m) and intercept (c) for y = mx + c
    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < xValues.length; i++) {
      var weight = weights[i];
      numerator += weight * (xValues[i] - xMean) * (yValues[i] - yMean);
      denominator += weight * (xValues[i] - xMean) * (xValues[i] - xMean);
    }

    _slope = numerator / denominator;
    _intercept = yMean - _slope * xMean;
  }

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  double get slope => _slope;

  @override
  String get type => 'Wls';

  @override
  int get xIntercept {
    return (-_intercept / _slope).round();
  }

  @override
  double predict(int x) {
    return _slope * x + _intercept;
  }
}
