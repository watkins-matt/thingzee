import 'package:repository/ml/regressor/regressor.dart';

class NaiveRegressor implements Regressor {
  final List<MapEntry<double, double>> data;

  NaiveRegressor(this.data);
  NaiveRegressor.fromMap(Map<double, double> map) : this(map.entries.toList());

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  bool get hasYIntercept => true;

  @override
  double get slope {
    // Calculate the time difference between the last two timestamps in milliseconds
    double dt = data.last.key - data[data.length - 2].key;

    // Calculate the value difference between the last two points
    double dv = data.last.value - data[data.length - 2].value;

    // Calculate the trend (slope)
    return dv / dt;
  }

  @override
  String get type => 'Naive';

  @override
  double get xIntercept {
    // Calculate the time difference between the last two timestamps in milliseconds
    double dt = data.last.key - data[data.length - 2].key;

    // Calculate the value difference between the last two points
    double dv = data.last.value - data[data.length - 2].value;

    // Calculate the trend
    double trend = dv / dt;

    // Calculate the time at which the trend line crosses the x-axis
    return data.last.key - (data.last.value / trend);
  }

  @override
  double get yIntercept => predict(0);

  @override
  double predict(double timestamp) {
    // Calculate the time difference between the last two timestamps in milliseconds
    double dt = data.last.key - data[data.length - 2].key;

    // Calculate the value difference between the last two points
    double dv = data.last.value - data[data.length - 2].value;

    // Calculate the trend
    double trend = dv / dt;

    // Estimate the time difference from the last known point to the prediction point
    double dtPred = timestamp - data.last.key;

    // Return the forecasted value
    return data.last.value + dtPred * trend;
  }
}
