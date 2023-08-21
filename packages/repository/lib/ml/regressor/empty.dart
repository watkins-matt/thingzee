import 'package:repository/ml/regressor/regressor.dart';

class EmptyRegressor implements Regressor {
  @override
  bool hasYIntercept = false;

  @override
  bool get hasSlope => false;

  @override
  bool get hasXIntercept => false;

  @override
  double get slope => 0;

  @override
  String get type => 'Empty';

  @override
  double get xIntercept => 0;

  @override
  double get yIntercept => 0;

  @override
  double predict(double x) {
    return 0;
  }
}
