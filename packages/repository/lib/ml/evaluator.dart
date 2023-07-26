import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';

class Evaluator {
  Map<String, Regressor> regressors = {};
  Regressor _best = EmptyRegressor();
  bool _trained = false;
  final String defaultType = 'Simple';
  final History history;

  Evaluator(this.history);

  Regressor get best {
    if (!_trained) {
      train(history);
    }

    // If there is any series with a length greater than one
    // then the best regressor should not be an EmptyRegressor
    if (history.series.any((s) => s.observations.length > 1)) {
      assert(_best.type != 'Empty' && _best.type != 'SinglePoint');
    }

    return _best;
  }

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

    // If the user has already said that we currently have 0,
    // we can say for certain that the value is 0 regardless
    // of what the regressors say.
    Observation? last = history.last;
    if (last != null && last.amount == 0) {
      return 0;
    }

    return best.predict(timestamp);
  }

  void train(History history) {
    if (history.series.isEmpty) {
      return;
    }

    int seriesId = 0;
    for (final series in history.series) {
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
        var points = series.toPoints();
        MapNormalizer normalizer = MapNormalizer(points);
        points = normalizer.dataPoints;

        var x1 = points.keys.elementAt(0);
        var y1 = points.values.elementAt(0);
        var x2 = points.keys.elementAt(1);
        var y2 = points.values.elementAt(1);

        final regressor = TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2);

        return [
          NormalizedRegressor.withBase(normalizer, regressor, history.baseTimestamp,
              yShift: history.baseAmount)
        ];
      default:
        var points = series.toPoints();
        MapNormalizer normalizer = MapNormalizer(points);
        points = normalizer.dataPoints;

        final simple = SimpleLinearRegressor(points);
        final naive = NaiveRegressor.fromMap(points);
        final holt = HoltLinearRegressor.fromMap(points, .85, .75);
        final shifted = ShiftedInterceptLinearRegressor(points);
        final weighted = WeightedLeastSquaresLinearRegressor(points);

        regressors.add(NormalizedRegressor.withBase(normalizer, simple, history.baseTimestamp,
            yShift: history.baseAmount));
        regressors.add(NormalizedRegressor.withBase(normalizer, naive, history.baseTimestamp,
            yShift: history.baseAmount));
        regressors.add(NormalizedRegressor.withBase(normalizer, holt, history.baseTimestamp,
            yShift: history.baseAmount));
        regressors.add(NormalizedRegressor.withBase(normalizer, shifted, history.baseTimestamp,
            yShift: history.baseAmount));
        regressors.add(NormalizedRegressor.withBase(normalizer, weighted, history.baseTimestamp,
            yShift: history.baseAmount));

      // final dataFrame = series.toDataFrame();
      // final dataFrameNormalizer = DataFrameNormalizer(dataFrame, 'amount');

      // Using the OLS Model
      // final olsRegressor = OLSRegressor();
      // olsRegressor.fit(dataFrameNormalizer.dataFrame, 'amount');
      // regressors.add(SimpleOLSRegressor(olsRegressor, dataFrameNormalizer));

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
