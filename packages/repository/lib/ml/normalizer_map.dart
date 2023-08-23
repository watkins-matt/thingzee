class MapNormalizer {
  Map<double, double> data;
  late double minTime;
  late double maxTime;
  late double minAmount;
  late double maxAmount;

  MapNormalizer(this.data) {
    minTime = data.keys.reduce((a, b) => a < b ? a : b);
    maxTime = data.keys.reduce((a, b) => a > b ? a : b);
    minAmount = data.values.reduce((a, b) => a < b ? a : b);
    maxAmount = data.values.reduce((a, b) => a > b ? a : b);
  }

  Map<double, double> get dataPoints {
    return data
        .map((timestamp, amount) => MapEntry(normalizeTime(timestamp), normalizeAmount(amount)));
  }

  double get range => maxTime - minTime;

  double denormalizeAmount(double normalizedAmount) {
    return normalizedAmount * maxAmount;
  }

  double denormalizeSlope(double slope) {
    return slope * maxAmount;
  }

  double denormalizeTime(double normalizedTimestamp) {
    return normalizedTimestamp + minTime;
  }

  double normalizeAmount(double amount) {
    return amount / maxAmount;
  }

  double normalizeTime(double timestamp) {
    return timestamp - minTime;
  }
}

class ScaledMapNormalizer {
  Map<double, double> data;
  late double minTime;
  late double maxTime;
  late double minAmount;
  late double maxAmount;

  ScaledMapNormalizer(this.data) {
    minTime = data.keys.reduce((a, b) => a < b ? a : b);
    maxTime = data.keys.reduce((a, b) => a > b ? a : b);
    minAmount = data.values.reduce((a, b) => a < b ? a : b);
    maxAmount = data.values.reduce((a, b) => a > b ? a : b);
  }

  Map<double, double> get dataPoints {
    return data
        .map((timestamp, amount) => MapEntry(normalizeTime(timestamp), normalizeAmount(amount)));
  }

  double denormalizeAmount(double normalizedAmount, double yScale) {
    return normalizedAmount * (maxAmount - minAmount) * yScale + minAmount * yScale;
  }

  double denormalizeTime(double normalizedTimestamp, double baseTimestamp) {
    return normalizedTimestamp * (maxTime - minTime) + baseTimestamp;
  }

  double normalizeAmount(double amount) {
    return (amount - minAmount) / (maxAmount - minAmount);
  }

  double normalizeTime(double timestamp) {
    return (timestamp - minTime) / (maxTime - minTime);
  }

  Map<double, double> transformData(double baseTimestamp, double yScale) {
    return dataPoints.map((normalizedTimestamp, normalizedAmount) => MapEntry(
          denormalizeTime(normalizedTimestamp, baseTimestamp),
          denormalizeAmount(normalizedAmount, yScale),
        ));
  }
}
