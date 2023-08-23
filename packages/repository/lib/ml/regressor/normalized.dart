import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor/regressor.dart';

class NormalizedRegressor implements Regressor {
  final Map<double, double> data;
  MapNormalizer normalizer;
  Regressor regressor;
  double baseTimestamp;
  double yScale;

  factory NormalizedRegressor(Regressor regressor, Map<double, double> data,
      {double? yScale, double? baseTimestamp}) {
    var normalizer = MapNormalizer(data);
    return NormalizedRegressor._(regressor, data,
        yScale: yScale ?? normalizer.maxAmount,
        normalizer: normalizer,
        baseTimestamp: baseTimestamp ?? normalizer.minTime);
  }

  NormalizedRegressor._(this.regressor, this.data,
      {required this.yScale, required this.normalizer, required this.baseTimestamp});

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

    return baseTimestamp + (yScaleProp * (regressor.xIntercept - normalizer.minTime));
  }

  @override
  double get yIntercept {
    return -slope * xIntercept;
  }

  /// Represents the proportion we are scaling by.
  /// For example, if we set yScale to 1 and the original amount was
  /// 3, then yScaleProp would be 1/3 because we are scaling down.
  /// If we set yScale to 3 and the original amount was 1, then
  /// yScaleProp would be 3 because we are scaling up.
  double get yScaleProp => yScale / normalizer.maxAmount;

  @override
  double predict(double x) {
    return slope * x + yIntercept;
  }
}
