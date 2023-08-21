import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';
import 'package:repository/ml/normalizer_df.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/ols_regressor.dart';
import 'package:repository/ml/regressor/regressor.dart';

class SimpleOLSRegressor implements Regressor {
  final OLSRegressor regressor;
  final DataFrameNormalizer normalizer;

  SimpleOLSRegressor(this.regressor, this.normalizer);

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

  @override
  bool get hasYIntercept => true;

  @override
  double get slope {
    // Note that the dataframe should be normalized, so predict 0
    // will return the y-intercept
    double yIntercept = predict(0);
    double xIntercept = this.xIntercept.toDouble();

    // calculate slope using (y2 - y1) / (x2 - x1)
    return (yIntercept - 0) / (xIntercept - 0);
  }

  @override
  String get type => 'Ols';

  @override
  double get xIntercept {
    // Define the search window for timestamps.
    double lowerBound = DateTime.now().millisecondsSinceEpoch.toDouble();
    double upperBound = lowerBound + 30 * 24 * 60 * 60 * 1000; // 30 days

    double predictedAmount;
    double mid;

    // Check if the upper bound is high enough
    var observation = Observation(
      timestamp: upperBound,
      amount: 0,
      householdCount: 2,
    );

    var matrix = Matrix.fromRows([Vector.fromList(observation.normalize(normalizer))]);
    var dataframe = DataFrame.fromMatrix(matrix, header: Observation.header);
    dataframe = dataframe.dropSeries(names: [regressor.target]);
    predictedAmount = regressor.predict(dataframe);

    // If the predicted amount at the upper bound is above zero,
    // continuously double the upper bound until the predicted amount is below zero.
    while (predictedAmount > 0) {
      upperBound *= 2;

      observation = Observation(
        timestamp: upperBound,
        amount: 0,
        householdCount: 2,
      );

      matrix = Matrix.fromRows([Vector.fromList(observation.normalize(normalizer))]);
      dataframe = DataFrame.fromMatrix(matrix, header: Observation.header);
      dataframe = dataframe.dropSeries(names: [regressor.target]);
      predictedAmount = regressor.predict(dataframe);
    }

    // Perform binary search
    int counter = 0;
    while ((upperBound - lowerBound).abs() > 1 && counter < 50) {
      mid = (lowerBound + upperBound) / 2;

      observation = Observation(
        timestamp: mid,
        amount: 0,
        householdCount: 2,
      );

      matrix = Matrix.fromRows([Vector.fromList(observation.normalize(normalizer))]);
      dataframe = DataFrame.fromMatrix(matrix, header: Observation.header);
      dataframe = dataframe.dropSeries(names: [regressor.target]);
      predictedAmount = regressor.predict(dataframe);

      if (predictedAmount > 0) {
        lowerBound = mid;
      } else {
        upperBound = mid;
      }

      counter++;
    }

    // Return the timestamp when amount runs out
    return upperBound;
  }

  @override
  double get yIntercept => predict(0);

  @override
  double predict(double x) {
    var observation = Observation(
      timestamp: x.toDouble(),
      amount: 0,
      householdCount: 2,
    );

    final vector = Vector.fromList(observation.normalize(normalizer));
    final matrix = Matrix.fromRows([vector]);

    var dataframe = DataFrame.fromMatrix(matrix, header: Observation.header);
    dataframe = dataframe.dropSeries(names: [regressor.target]);

    var predicted = regressor.predict(dataframe);
    return predicted;
  }
}
