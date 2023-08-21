import 'package:repository/ml/regressor/regressor.dart';

class UsageRateDaysRegressor implements Regressor {
  final double _slope;
  final double _intercept;

  factory UsageRateDaysRegressor(double usageRateDays, int x1, double y1) {
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
  double get slope => _slope;

  @override
  String get type => 'UsageSpeedDays';

  @override
  int get xIntercept {
    return (-_intercept / _slope).round();
  }

  double get yIntercept => _intercept;

  @override
  double predict(int x) {
    return _slope * x + _intercept;
  }
}
