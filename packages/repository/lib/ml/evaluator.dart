import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/normalizer_df.dart';
import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/ols_regressor.dart';
import 'package:repository/ml/regressor.dart';

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
    if (history.allSeries.isEmpty) {
      return;
    }

    int seriesId = 0;
    for (final series in history.allSeries) {
      var regressorList = _generateRegressors(series);

      for (final regressor in regressorList) {
        regressors['${regressor.type}-$seriesId'] = regressor;

        if (regressor.type != 'Empty' && regressor.type != 'SinglePoint') {
          _best = regressor;
        }
      }

      seriesId++;
    }

    _trained = true;
  }

  List<Regressor> _generateRegressors(HistorySeries series) {
    List<Regressor> regressors = [];

    switch (series.observations.length) {
      case 0:
      case 1:
        return [];
      case 2:
        var x1 = series.observations[0].timestamp.toInt();
        var y1 = series.observations[0].amount;
        var x2 = series.observations[1].timestamp.toInt();
        var y2 = series.observations[1].amount;
        return [TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2)];
      default:
        final points = series.toPoints();
        MapNormalizer normalizer = MapNormalizer(points);

        final simple = SimpleLinearRegressor(points);
        final naive = NaiveRegressor.fromMap(points);
        final holt = HoltLinearRegressor.fromMap(points, .85, .75);
        final shifted = ShiftedInterceptLinearRegressor(points);
        final weighted = WeightedLeastSquaresLinearRegressor(points);

        regressors.add(NormalizedRegressor(normalizer, simple));
        regressors.add(NormalizedRegressor(normalizer, naive));
        regressors.add(NormalizedRegressor(normalizer, holt));
        regressors.add(NormalizedRegressor(normalizer, shifted));
        regressors.add(NormalizedRegressor(normalizer, weighted));

        final dataFrame = series.toDataFrame();
        final dataFrameNormalizer = DataFrameNormalizer(dataFrame, 'amount');

        // Using the OLS Model
        final olsRegressor = OLSRegressor();
        olsRegressor.fit(dataFrameNormalizer.dataFrame, 'amount');
        regressors.add(SimpleOLSRegressor(olsRegressor, dataFrameNormalizer));

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
}
