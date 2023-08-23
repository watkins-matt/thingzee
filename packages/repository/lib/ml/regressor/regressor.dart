import 'package:repository/ml/regressor/normalized.dart';

abstract class Regressor {
  bool get hasSlope;
  bool get hasXIntercept;
  bool get hasYIntercept;
  double get slope;
  String get type;
  double get xIntercept;
  double get yIntercept;
  double predict(double x);
}

extension Formula on Regressor {
  String get formula {
    return 'y = ${slope.toStringAsExponential(2)}x + ${yIntercept.toStringAsExponential(20)}';
  }
}

extension NormalizedUsageRateDaysCalculator on NormalizedRegressor {
  double get daysToXIntercept {
    double xInterceptDifference = xIntercept - baseTimestamp;
    // Convert the difference from milliseconds to days
    return xInterceptDifference / 86400000;
  }
}

extension UsageRateDaysCalculator on Regressor {
  double get usageRateDays {
    if (hasSlope && slope != 0) {
      return (1 / slope.abs()) / 1000 / 60 / 60 / 24;
    }
    return 0;
  }

  double daysToXIntercept(double baseTimestamp) {
    double xInterceptDifference = xIntercept - baseTimestamp;
    // Convert the difference from milliseconds to days
    return xInterceptDifference / 86400000;
  }
}
