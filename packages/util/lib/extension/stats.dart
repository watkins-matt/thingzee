import 'dart:math' as m;

extension Stats on List<num> {
  num get max {
    assert(length > 0);

    // If there is only one item, return that
    if (length == 1) {
      return this[0];
    }

    return fold(this[0], m.max);
  }

  num get mean {
    return length > 0 ? sum / length : 0;
  }

  num get min {
    assert(length > 0);

    // There is only one item, return that
    if (length == 1) {
      return this[0];
    }

    return fold(this[0], m.min);
  }

  num get sum {
    return fold(0, (a, b) => a + b);
  }
}

extension StatsXY on Map<int, double> {
  double get last {
    return x.max.toDouble();
  }

  double get regression {
    // We must have at least two points to calculate regression
    if (isEmpty || length == 1) return 0;

    List<num> xValues = x;
    List<num> yValues = y;

    // It is very likely the oldest point is an outlier,
    // remove it if we have two other points
    if (xValues.length >= 3) {
      num firstTimestamp = xValues.min;
      num firstValue = this[firstTimestamp]!;

      xValues.remove(firstTimestamp);
      yValues.remove(firstValue);
    }

    num xMean = xValues.mean;
    num yMean = yValues.mean;

    List<num> xDiffAvg = [];
    List<num> xDiffAvgSquared = [];

    for (final xValue in xValues) {
      final value = xValue - xMean;
      xDiffAvg.add(value);

      num valueSq = m.pow(value, 2);
      xDiffAvgSquared.add(valueSq);
    }

    List<num> yDiffAvg = [];
    List<num> diffAvgMultiplied = [];
    for (int i = 0; i < yValues.length; i++) {
      final value = yValues[i] - yMean;
      yDiffAvg.add(value);

      final multiplied = value * xDiffAvg[i];
      diffAvgMultiplied.add(multiplied);
    }

    return diffAvgMultiplied.sum / xDiffAvgSquared.sum;
  }

  double get usageSpeedDays {
    return regression == 0 ? 0 : (1 / regression.abs()) / 1000 / 60 / 60 / 24;
  }

  double get usageSpeedMinutes {
    return regression == 0 ? 0 : (1 / regression.abs()) / 1000 / 60;
  }

  List<int> get x => keys.toList();

  double get xIntercept {
    return (0 - yIntercept) / regression;
  }

  List<double> get y => values.toList();

  double get yIntercept {
    return y.mean - (regression * x.mean);
  }

  String getFormula() {
    return 'y = ${regression}x + $yIntercept';
  }

  double predict(double xValue) {
    final result = (regression * xValue) + yIntercept;
    return result;
  }

  double predictWithSlope(double xValue, double slope) {
    double newIntercept = y.mean - (slope * x.mean);
    final result = (slope * xValue) + newIntercept;
    return result;
  }

  Map<String, String> toJson() {
    Map<String, String> json = {};
    for (final entry in entries) {
      json[entry.key.toString()] = entry.value.toString();
    }

    return json;
  }

  double yInterceptWithSlope(double slope) {
    return y.mean - (slope * x.mean);
  }
}
