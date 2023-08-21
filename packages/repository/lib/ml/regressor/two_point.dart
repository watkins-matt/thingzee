import 'package:repository/ml/regressor/regressor.dart';

class TwoPointLinearRegressor implements Regressor {
  final double _slope;
  final double _intercept;

  TwoPointLinearRegressor(this._slope, this._intercept);
  TwoPointLinearRegressor.fromPoints(double x1, double y1, double x2, double y2)
      : _slope = (y2 - y1) / (x2 - x1),
        _intercept = y1 - (y2 - y1) / (x2 - x1) * x1;

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  bool get hasYIntercept => true;

  @override
  double get slope => _slope;

  @override
  String get type => 'TwoPoint';

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
