import 'package:repository/ml/regressor/regressor.dart';

class HoltLinearRegressor extends Regressor {
  final List<MapEntry<int, double>> data;
  final double alpha;
  final double beta;

  HoltLinearRegressor(this.data, this.alpha, this.beta);

  HoltLinearRegressor.fromMap(Map<int, double> mapData, this.alpha, this.beta)
      : data = mapData.entries.toList();

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  double get slope {
    _HoltLinearResult result = _calculateHoltLinear();
    // Return the final calculated trend as the slope.
    return result.trend;
  }

  @override
  String get type => 'Holt';

  @override
  int get xIntercept {
    _HoltLinearResult result = _calculateHoltLinear();

    // The time when the trend hits zero is when level + dt * trend = 0, solving for dt gives.
    int dtZero = (-result.level / result.trend).round();

    // Return the timestamp when the trend is expected to hit zero.
    return data.last.key + dtZero;
  }

  @override
  double predict(int x) {
    _HoltLinearResult result = _calculateHoltLinear();

    // Estimate the time difference from the last known point to the prediction point.
    int dtPred = x - data.last.key;

    // Return the forecasted value.
    return result.level + dtPred * result.trend;
  }

  // A private method to calculate the current level and trend using Holt's Linear Exponential Smoothing.
  _HoltLinearResult _calculateHoltLinear() {
    // Define the initial level and trend.
    double level = data[0].value;
    double trend = (data[1].value - data[0].value) /
        (data[1].key - data[0].key); // Initial slope between the first two points

    // Iteratively apply Holt's Linear Exponential Smoothing.
    for (var i = 1; i < data.length; i++) {
      // Calculate the time difference between current and previous timestamp.
      int dt = data[i].key - data[i - 1].key;

      // Forecast the value for the current timestamp using the previous level and trend.
      double forecast = level + dt * trend;

      // Update the level using the alpha smoothing parameter.
      double oldLevel = level;
      level = alpha * data[i].value + (1 - alpha) * forecast;

      // Update the trend using the beta smoothing parameter.
      trend = beta * (level - oldLevel) / dt + (1 - beta) * trend;
    }

    return _HoltLinearResult(level, trend);
  }
}

class _HoltLinearResult {
  final double level;
  final double trend;

  _HoltLinearResult(this.level, this.trend);
}
