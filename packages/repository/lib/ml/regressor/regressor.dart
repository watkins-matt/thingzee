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
    return 'y = ${slope.toStringAsExponential(2)}x + ${yIntercept.toStringAsExponential(2)}';
  }
}

extension UsageRateDaysCalculator on Regressor {
  double get usageRateDays {
    if (hasSlope && slope != 0) {
      return (1 / slope.abs()) / 1000 / 60 / 60 / 24;
    }
    return 0;
  }
}
