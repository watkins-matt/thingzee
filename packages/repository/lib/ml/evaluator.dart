import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/normalizer.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/ols_regressor.dart';
import 'package:repository/ml/regressor.dart';

import 'history.dart';

class Evaluator {
  Map<String, Regressor> regressors = {};
  Regressor _best = EmptyRegressor();
  bool _trained = false;
  final String defaultType = 'Simple';
  final History history;

  Evaluator(this.history);

  bool get trained => _trained;

  Map<String, double> allPredictions(int timestamp) {
    if (!_trained) {
      throw Exception('Evaluator has not been trained. Train before predicting.');
    }

    final predictions = <String, double>{};

    for (final modelEntry in regressors.entries) {
      final regressor = modelEntry.value;
      final prediction = regressor.predict(timestamp);
      predictions[modelEntry.key] = prediction;
    }

    return predictions;
  }

  Regressor get best {
    if (!_trained) {
      train(history);
    }
    return _best;
  }

  void assess(Observation observation) {
    if (!_trained) {
      throw Exception('Evaluator has not been trained. Train before assessing.');
    }

    double targetAmount = observation.amount;
    double minimumDistance = double.maxFinite;

    for (final modelEntry in regressors.entries) {
      final regressor = modelEntry.value;
      final prediction = regressor.predict(observation.timestamp.toInt());
      final distance = (prediction - targetAmount).abs();

      if (distance < minimumDistance) {
        minimumDistance = distance;
        _best = regressor;
      }
    }
  }

  double predict(int timestamp) {
    if (!_trained) {
      throw Exception('Evaluator has not been trained. Train before predicting.');
    }

    return best.predict(timestamp);
  }

  void train(History history) {
    if (history.allSeries.isEmpty || history.allSeries.last.observations.isEmpty) {
      return;
    }

    int seriesId = history.allSeries.length - 1;
    final series = history.allSeries.last;
    final regressorList = _generateRegressors(series);

    // Add the regressors to the map
    for (final regressor in regressorList) {
      regressors['${regressor.type}-$seriesId'] = regressor;
    }

    // We haven't initialized the best regressor yet
    if (!_trained) {
      _trained = true;
      _best = regressors['$defaultType-$seriesId'] ?? regressorList.last;
    }
  }
}

List<Regressor> _generateRegressors(HistorySeries series) {
  List<Regressor> regressors = [];

  switch (series.observations.length) {
    case 0:
      return [EmptyRegressor()];
    case 1:
      return [SingleDataPointLinearRegressor(series.observations[0].amount)];
    case 2:
      var x1 = series.observations[0].timestamp.toInt();
      var y1 = series.observations[0].amount;
      var x2 = series.observations[1].timestamp.toInt();
      var y2 = series.observations[1].amount;
      return [TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2)];
    default:
      final points = series.toPoints();

      regressors.add(SimpleLinearRegressor(points));
      regressors.add(NaiveRegressor.fromMap(points));
      regressors.add(HoltLinearRegressor.fromMap(points, .85, .75));
      regressors.add(ShiftedInterceptLinearRegressor(points));
      regressors.add(WeightedLeastSquaresLinearRegressor(points));

      final dataFrame = series.toDataFrame();
      final normalizer = Normalizer(dataFrame, 'amount');

      // Using the OLS Model
      final olsRegressor = OLSRegressor();
      olsRegressor.fit(normalizer.dataFrame, 'amount');
      regressors.add(SimpleOLSRegressor(olsRegressor, normalizer));

    // Using the SGD Model
    // final regressor = LinearRegressor.SGD(normalizer.dataFrame, 'amount',
    //     fitIntercept: true,
    //     interceptScale: .25,
    //     iterationLimit: 5000,
    //     initialLearningRate: 1,
    //     learningRateType: LearningRateType.constant);
    // return MLLinearRegressor(regressor, normalizer);
  }

  return regressors;
}
