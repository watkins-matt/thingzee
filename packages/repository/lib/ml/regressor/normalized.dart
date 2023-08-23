import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor/regressor.dart';

class NormalizedRegressor implements Regressor {
  final Map<double, double> data;
  MapNormalizer normalizer;
  Regressor regressor;
  double baseTimestamp;
  double yScale;

  factory NormalizedRegressor(Regressor regressor, Map<double, double> data,
      {double yScale = 1.0, double? baseTimestamp}) {
    var normalizer = MapNormalizer(data);
    return NormalizedRegressor._(regressor, data,
        yScale: yScale, normalizer: normalizer, baseTimestamp: baseTimestamp ?? normalizer.minTime);
  }

  NormalizedRegressor._(this.regressor, this.data,
      {this.yScale = 1.0, required this.normalizer, required this.baseTimestamp});

  @override
  bool get hasSlope => regressor.hasSlope;

  @override
  bool get hasXIntercept => regressor.hasXIntercept;

  @override
  bool get hasYIntercept => regressor.hasYIntercept;

  double get shift => baseTimestamp - normalizer.minTime;

  @override
  double get slope => regressor.slope;

  @override
  String get type => regressor.type;

  @override
  double get xIntercept {
    if (slope == 0.0) {
      return double.infinity;
    }

    return baseTimestamp + (yScale * (regressor.xIntercept - normalizer.minTime));
  }

  @override
  double get yIntercept {
    return -slope * xIntercept;
  }

  @override
  double predict(double x) {
    return slope * x + yIntercept;
  }
}
