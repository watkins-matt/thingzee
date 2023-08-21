import 'package:repository/ml/regressor/regressor.dart';

class NaiveRegressor implements Regressor {
  final List<MapEntry<int, double>> data;

  NaiveRegressor(this.data);
  NaiveRegressor.fromMap(Map<int, double> map) : this(map.entries.toList());

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  double get slope {
    // Calculate the time difference between the last two timestamps in milliseconds
    int dt = data.last.key - data[data.length - 2].key;

    // Calculate the value difference between the last two points
    double dv = data.last.value - data[data.length - 2].value;

    // Calculate the trend (slope)
    return dv / dt;
  }

  @override
  String get type => 'Naive';

  @override
  int get xIntercept {
    // Calculate the time difference between the last two timestamps in milliseconds
    int dt = data.last.key - data[data.length - 2].key;

    // Calculate the value difference between the last two points
    double dv = data.last.value - data[data.length - 2].value;

    // Calculate the trend
    double trend = dv / dt;

    // Calculate the time at which the trend line crosses the x-axis
    return (data.last.key - (data.last.value / trend)).toInt();
  }

  @override
  double predict(int timestamp) {
    // Calculate the time difference between the last two timestamps in milliseconds
    int dt = data.last.key - data[data.length - 2].key;

    // Calculate the value difference between the last two points
    double dv = data.last.value - data[data.length - 2].value;

    // Calculate the trend
    double trend = dv / dt;

    // Estimate the time difference from the last known point to the prediction point
    int dtPred = timestamp - data.last.key;

    // Return the forecasted value
    return data.last.value + dtPred * trend;
  }
}
