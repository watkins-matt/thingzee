abstract class Regressor {
  bool get hasSlope;
  bool get hasXIntercept;
  double get slope;
  String get type;
  int get xIntercept;
  double predict(int x);
}

extension UsageRateDaysCalculator on Regressor {
  double get usageRateDays {
    if (hasSlope && slope != 0) {
      return (1 / slope.abs()) / 1000 / 60 / 60 / 24;
    }
    return 0;
  }
}
