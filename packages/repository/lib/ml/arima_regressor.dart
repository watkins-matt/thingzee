import 'package:ml_linalg/linalg.dart';

class ArimaRegressor {
  Vector arCoeffs = Vector.empty();
  Vector maCoeffs = Vector.empty();
  Vector errors = Vector.empty();
  Vector data = Vector.empty(); // original series
  Vector diffData = Vector.empty(); // differenced series
  int d; // order of non-seasonal differencing
  int D; // order of seasonal differencing

  ArimaRegressor(this.d, this.D);

  void fit(List<MapEntry<double, double>> input) {
    // Create a time-indexed map for easy access
    Map<double, double> seriesMap = Map.fromEntries(input);
    // Assume input timestamps are sorted

    double startTime = 0;
    double endTime = 1;

    // Interpolate the series to get a regularly spaced time series
    List<double> seriesList = [];
    for (double t = startTime; t <= endTime; t += 0.1) {
      if (seriesMap.containsKey(t)) {
        seriesList.add(seriesMap[t]!);
      } else {
        // If there's a missing timestamp, interpolate
        double previousTimestamp = t - 0.1;
        while (!seriesMap.containsKey(previousTimestamp)) {
          previousTimestamp -= 0.1;
        }
        double nextTimestamp = t + 0.1;
        while (!seriesMap.containsKey(nextTimestamp)) {
          nextTimestamp += 0.1;
        }
        double interpolatedValue = seriesMap[previousTimestamp]! +
            (seriesMap[nextTimestamp]! - seriesMap[previousTimestamp]!) *
                ((t - previousTimestamp) / (nextTimestamp - previousTimestamp));
        seriesList.add(interpolatedValue);
      }
    }

    Vector series = Vector.fromList(seriesList);
    data = series;
    diffData = difference(series, d + D);
    arCoeffs = estimateARCoeffs(diffData, d, D);
    errors = calculateErrors(diffData, arCoeffs);
    maCoeffs = estimateMACoeffs(errors, d);
  }

  double predict(double x) {
    if (arCoeffs.isNotEmpty && maCoeffs.isNotEmpty && errors.isNotEmpty) {
      int steps = ((x - 1) / 0.1).ceil();
      int start = diffData.length - steps;

      double lastValue = diffData.subvector(start - d + 1, start + 1).sum();
      double arSum = arCoeffs.dot(diffData.subvector(start - arCoeffs.length, start));
      double maSum = maCoeffs.dot(errors.subvector(start - maCoeffs.length, start));

      double prediction = lastValue + arSum + maSum;
      prediction = undifference(prediction, data, d + D);

      // Interpolate if x does not align with a step
      if (x % 0.1 != 0) {
        double previousTimestamp = steps * 0.1;
        double nextTimestamp = (steps + 1) * 0.1;
        double previousValue = predict(previousTimestamp);
        double nextValue = predict(nextTimestamp);
        prediction = previousValue +
            (nextValue - previousValue) *
                ((x - previousTimestamp) / (nextTimestamp - previousTimestamp));
      }

      return prediction;
    } else {
      throw Exception('The model is not fitted yet.');
    }
  }

  Vector estimateARCoeffs(Vector series, int p, int d) {
    Vector Y = series.subvector(p, series.length);
    Matrix X = armaMatrix(series, p, d);
    Matrix B = (X.transpose() * X).inverse() * X.transpose() * Y;
    return B.getColumn(0);
  }

  Vector calculateErrors(Vector series, Vector coeffs) {
    Matrix predictedMatrix = armaMatrix(series, coeffs.length, 0) * coeffs;
    Vector predicted = predictedMatrix.getColumn(0);
    return series.subvector(coeffs.length, series.length) - predicted;
  }

  Vector estimateMACoeffs(Vector errors, int q) {
    Vector Y = errors.subvector(q, errors.length);
    Matrix X = armaMatrix(errors, q, 0);
    Matrix B = (X.transpose() * X).inverse() * X.transpose() * Y;
    return B.getColumn(0);
  }

  Matrix armaMatrix(Vector series, int p, int q) {
    int n = series.length;
    var matrixData = <Vector>[];
    for (int i = p + q - 1; i < n; i++) {
      Vector row = series.subvector(i - p - q + 1, i + 1);
      matrixData.add(row);
    }
    return Matrix.fromRows(matrixData);
  }

  Vector difference(Vector series, int order, [int lag = 1]) {
    Vector differenced = series;
    for (int i = 0; i < order; i++) {
      differenced = _lagDifference(differenced, lag);
    }
    return differenced;
  }

  Vector _lagDifference(Vector series, int lag) {
    var output = <double>[];
    for (int i = lag; i < series.length; i++) {
      output.add(series[i] - series[i - lag]);
    }
    return Vector.fromList(output);
  }

  double undifference(double value, Vector series, int order, [int lag = 1]) {
    double undifferenced = value;
    for (int i = 0; i < order; i++) {
      undifferenced = _lagUndifference(undifferenced, series, lag);
    }
    return undifferenced;
  }

  double _lagUndifference(double value, Vector series, int lag) {
    return value + series[series.length - lag];
  }
}

extension VectorOperations on Vector {
  double sumOfSquares() {
    return fold(0, (sum, x) => sum + x * x);
  }

  double get variance {
    var mean = this.mean();
    var sum = 0.0;
    for (final x in this) {
      sum += (x - mean) * (x - mean);
    }
    return sum / length;
  }

  Vector autocorr() {
    final n = length;
    if (n == 0) {
      return Vector.empty(); // return empty vector for an empty input
    }

    if (n == 1) {
      return Vector.fromList([double.nan]); // return a vector with NaN for single element input
    }

    final mean = this.mean();
    final variance = this.variance;
    var output = Vector.filled(n, 0.0);

    for (var lag = 0; lag < n; lag++) {
      for (var i = 0; i < n - lag; i++) {
        output = output.set(lag, output[lag] + (this[i] - mean) * (this[i + lag] - mean));
      }
      output = output.set(lag, output[lag] / variance);
    }

    // Normalize the output
    final norm = output[0];
    for (var i = 0; i < n; i++) {
      output = output.set(i, output[i] / norm);
    }

    return output;
  }
}
