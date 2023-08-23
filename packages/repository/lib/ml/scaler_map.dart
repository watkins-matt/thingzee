class MapScaler {
  final Map<double, double> data;
  final double scale;
  final double baseTimestamp;

  MapScaler(this.data, this.scale, this.baseTimestamp);

  Map<double, double> get scaledDataPoints {
    double previousOriginalTime = data.keys.first;
    double previousScaledTime = scaleTime(previousOriginalTime);

    Map<double, double> scaledData = {
      previousScaledTime: scaleAmount(data[previousOriginalTime]!),
    };

    data.forEach((timestamp, amount) {
      if (timestamp != previousOriginalTime) {
        double timeDifference = (timestamp - previousOriginalTime) * scale;
        double scaledTime = previousScaledTime + timeDifference;
        scaledData[scaledTime] = scaleAmount(amount);
        previousOriginalTime = timestamp;
        previousScaledTime = scaledTime;
      }
    });

    return scaledData;
  }

  double scaleAmount(double amount) {
    return amount * scale;
  }

  double scaleTime(double timestamp) {
    return timestamp + baseTimestamp;
  }
}
