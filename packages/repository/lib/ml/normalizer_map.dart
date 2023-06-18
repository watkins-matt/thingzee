class MapNormalizer {
  Map<int, double> data;
  late int minTime;
  late double maxAmount;

  MapNormalizer(this.data) {
    minTime = data.keys.reduce((a, b) => a < b ? a : b);
    maxAmount = data.values.reduce((a, b) => a > b ? a : b);
  }

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

  Map<int, double> get dataPoints {
    return data
        .map((timestamp, amount) => MapEntry(normalizeTime(timestamp), normalizeAmount(amount)));
  }
}
