import 'package:repository/ml/regressor/regressor.dart';

class SingleDataPointLinearRegressor implements Regressor {
  final double intercept;
  SingleDataPointLinearRegressor(this.intercept);

  @override
  bool get hasSlope => false;

  @override
  bool get hasXIntercept => false;

  @override
  double get slope => 0;

  @override
  String get type => 'SinglePoint';

  @override
  int get xIntercept => 0;

  @override
  double predict(int x) {
    return intercept;
  }
}
