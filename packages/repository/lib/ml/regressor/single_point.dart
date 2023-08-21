import 'package:repository/ml/regressor/regressor.dart';

class SingleDataPointLinearRegressor implements Regressor {
  final double intercept;
  SingleDataPointLinearRegressor(this.intercept);

  @override
  bool get hasSlope => false;

  @override
  bool get hasXIntercept => false;

  @override
  bool get hasYIntercept => true;

  @override
  double get slope => 0;

  @override
  String get type => 'SinglePoint';

  @override
  double get xIntercept => 0;

  @override
  double get yIntercept => intercept;

  @override
  double predict(double x) {
    return intercept;
  }
}
