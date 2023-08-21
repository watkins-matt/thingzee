import 'package:repository/ml/regressor/regressor.dart';

class UsageRateDaysRegressor implements Regressor {
  final double _slope;
  final double _intercept;

  factory UsageRateDaysRegressor(double usageRateDays, double x1, double y1) {
    final slope = -1 / (usageRateDays * 24 * 60 * 60 * 1000);
    final intercept = y1 + (x1 * slope);
    return UsageRateDaysRegressor._(slope, intercept);
  }

  UsageRateDaysRegressor._(this._slope, this._intercept);

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  bool get hasYIntercept => true;

  @override
  double get slope => _slope;

  @override
  String get type => 'UsageSpeedDays';

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
