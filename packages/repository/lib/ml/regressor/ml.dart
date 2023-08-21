import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';
import 'package:repository/ml/normalizer_df.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor/regressor.dart';

class MLLinearRegressor implements Regressor {
  final LinearRegressor regressor;
  final DataFrameNormalizer normalizer;

  MLLinearRegressor(this.regressor, this.normalizer);

  @override
  bool get hasSlope => true;

  @override
  bool get hasXIntercept => true;

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
  String get type => 'MLLinear';

  @override
  int get xIntercept {
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
    var dataframe = DataFrame.fromMatrix(matrix);
    predictedAmount = regressor.predict(dataframe)[0].data.first;

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
      dataframe = DataFrame.fromMatrix(matrix);
      predictedAmount = regressor.predict(dataframe)[0].data.first;
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
      dataframe = DataFrame.fromMatrix(matrix);
      predictedAmount = regressor.predict(dataframe)[0].data.first;

      if (predictedAmount > 0) {
        lowerBound = mid;
      } else {
        upperBound = mid;
      }

      counter++;
    }

    // Return the timestamp when amount runs out
    return upperBound.round();
  }

  @override
  double predict(int x) {
    var observation = Observation(
      timestamp: x.toDouble(),
      amount: 0,
      householdCount: 2,
    );

    final vector = Vector.fromList(observation.normalize(normalizer));
    final matrix = Matrix.fromRows([vector]);
    var dataframe = DataFrame.fromMatrix(matrix, header: Observation.header);

    final df = dataframe.dropSeries(names: [regressor.targetName]);

    var predicted = regressor.predict(df);
    return predicted[0].data.first;
  }
}
