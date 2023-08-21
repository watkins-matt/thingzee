import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor/regressor.dart';

class NormalizedRegressor implements Regressor {
  MapNormalizer normalizer;
  Regressor regressor;
  int baseTimestamp;
  double yShift;

  NormalizedRegressor(this.normalizer, this.regressor, {this.yShift = 0.0})
      : baseTimestamp = normalizer.minTime;
  NormalizedRegressor.withBase(this.normalizer, this.regressor, this.baseTimestamp,
      {this.yShift = 0.0});

  @override
  bool get hasSlope => regressor.hasSlope;

  @override
  bool get hasXIntercept => regressor.hasXIntercept;

  @override
  double get slope => normalizer.denormalizeSlope(regressor.slope);

  @override
  String get type => regressor.type;

  @override
  int get xIntercept {
    if (yShift == 0) {
      return regressor.xIntercept + baseTimestamp;
    } else {
      final yInterceptShifted = regressor.predict(0);
      return ((-yInterceptShifted / regressor.slope) + baseTimestamp).round();
    }
  }

  @override
  double predict(int x) {
    var normalizedX = x - baseTimestamp;
    var normalizedPrediction = regressor.predict(normalizedX);

    if (yShift == 0) {
      return normalizer.denormalizeAmount(normalizedPrediction);
    } else {
      final scaleFactor = normalizer.normalizeAmount(yShift);
      return normalizer.denormalizeAmount(normalizedPrediction) * scaleFactor;
    }
  }
}
