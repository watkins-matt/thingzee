class MapScaler {
  final Map<double, double> data;
  final double yScale;
  final double xScale;
  final double? baseX;

  MapScaler(
    this.data, {
    this.yScale = 1.0,
    this.xScale = 1.0,
    this.baseX,
  });

  Map<double, double> get scaledDataPoints {
    Map<double, double> scaledData = {};

    data.forEach((timestamp, amount) {
      double scaledTime = timestamp * xScale + (baseX ?? 0);
      double scaledAmount = amount * yScale;
      scaledData[scaledTime] = scaledAmount;
    });

    return scaledData;
  }
}
