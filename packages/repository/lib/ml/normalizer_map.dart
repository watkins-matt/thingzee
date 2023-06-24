class MapNormalizer {
  Map<int, double> data;
  late int minTime;
  late int maxTime;
  late double minAmount;
  late double maxAmount;

  MapNormalizer(this.data) {
    minTime = data.keys.reduce((a, b) => a < b ? a : b);
    maxTime = data.keys.reduce((a, b) => a > b ? a : b);
    minAmount = data.values.reduce((a, b) => a < b ? a : b);
    maxAmount = data.values.reduce((a, b) => a > b ? a : b);
  }

  int get range => maxTime - minTime;

  int normalizeTime(int timestamp) {
    return timestamp - minTime;
  }

  double normalizeAmount(double amount) {
    return amount / maxAmount;
  }

  int denormalizeTime(int normalizedTimestamp) {
    return normalizedTimestamp + minTime;
  }

  double denormalizeAmount(double normalizedAmount) {
    return normalizedAmount * maxAmount;
  }

  double denormalizeSlope(double slope) {
    var xRange = maxTime - minTime;
    var yRange = maxAmount - minAmount;
    return slope * (yRange / xRange);
  }

  Map<int, double> get dataPoints {
    return data
        .map((timestamp, amount) => MapEntry(normalizeTime(timestamp), normalizeAmount(amount)));
  }
}
