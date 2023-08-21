import 'package:repository/ml/regressor/regressor.dart';

class EmptyRegressor implements Regressor {
  @override
  bool get hasSlope => false;

  @override
  bool get hasXIntercept => false;

  @override
  double get slope => 0;

  @override
  String get type => 'Empty';

  @override
  int get xIntercept => 0;

  @override
  double predict(int x) {
    return 0;
  }
}
