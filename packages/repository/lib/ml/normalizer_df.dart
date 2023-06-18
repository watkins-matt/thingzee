import 'package:ml_dataframe/ml_dataframe.dart';

class DataFrameNormalizer {
  DataFrame df;
  String target;
  late Map<String, double> minValues;
  late Map<String, double> maxValues;

  DataFrameNormalizer(this.df, this.target) {
    minValues = {};
    maxValues = {};

    for (final column in df.header) {
      double minValue = double.infinity;
      double maxValue = double.negativeInfinity;

      var series = df[column].data.cast<double>();

      for (final value in series) {
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }

      minValues[column] = minValue;
      maxValues[column] = maxValue;
    }
  }

  double normalizeValue(String column, double value) {
    var minValue = minValues[column]!;
    var maxValue = maxValues[column]!;

    return (value - minValue) / (maxValue - minValue);
  }

  double denormalizeValue(String column, double value) {
    var minValue = minValues[column]!;
    var maxValue = maxValues[column]!;

    return value * (maxValue - minValue) + minValue;
  }

  DataFrame get dataFrame {
    List<Series> normalizedSeries = [];

    for (final column in df.header) {
      var series = df[column].data.cast<double>();

      if (column != target) {
        var columnSeries = series.map((value) => normalizeValue(column, value)).toList();
        normalizedSeries.add(Series(column, columnSeries));
      } else {
        normalizedSeries.add(Series(column, series.toList()));
      }
    }

    return DataFrame.fromSeries(normalizedSeries);
  }
}
