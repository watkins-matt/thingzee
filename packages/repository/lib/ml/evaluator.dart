import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';

class Evaluator {
  Map<String, Regressor> regressors = {};
  String _best = '';
  bool _trained = false;
  final String defaultType = 'Simple';
  final History history;

  Evaluator(this.history);

  Regressor get best {
    final bestRegressor = regressors[_best];
    if (_best.isEmpty || bestRegressor == null) {
      return EmptyRegressor();
    }

    if (!_trained) {
      train(history);
    }

    // If there is any series with a length greater than one
    // then the best regressor should not be an EmptyRegressor
    if (history.series.any((s) => s.observations.length > 1)) {
      assert(bestRegressor.type != 'Empty' && bestRegressor.type != 'SinglePoint');
    }

    return bestRegressor;
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

  /// Updates the best regressor based on which one was
  /// able to most accurately predict the newest observation.
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
        _best = modelEntry.key;
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

  /// Trains the evaluator by generating all possible regressors
  /// and then evaluating them against every series to determine
  /// which regressor is the best, giving more weight to the
  /// most recent series.
  void train(History history) {
    if (history.series.isEmpty) {
      return;
    }

    // First initialize the regressors
    int seriesId = 0;
    for (final series in history.series) {
      var regressorList = _generateRegressors(series);

      for (final regressor in regressorList) {
        final regressorId = '${regressor.type}-$seriesId';
        regressors[regressorId] = regressor;
      }

      seriesId++;
    }

    // Can't train if we have no regressors. This happens if we only
    // have one series with a single point.
    if (regressors.isEmpty) {
      return;
    }

    double minError = double.infinity;
    String bestRegressorId = regressors.keys.last;
    double lastSeriesWeight = 3;

    for (final regressorId in regressors.keys) {
      final regressor = regressors[regressorId]!;

      if (regressor.type != 'Empty' && regressor.type != 'SinglePoint') {
        final averageError = _evaluateRegressor(regressor, history.series, lastSeriesWeight);

        // If the average error was lower, we have a new best regressor
        if (averageError < minError) {
          minError = averageError;
          bestRegressorId = regressorId;
        }
      }
    }

    _best = bestRegressorId;
    _trained = true;
    // Log.d('Best regressor [${history.upc}]: $_best with average error of $minError');
  }

  double _computeMSE(Regressor regressor, HistorySeries series) {
    double errorSum = 0;
    int count = 0;

    final pointsMap = series.toPoints();

    for (final entry in pointsMap.entries) {
      final predictedValue = regressor.predict(entry.key);
      final trueValue = entry.value;

      errorSum += (trueValue - predictedValue) * (trueValue - predictedValue);
      count++;
    }

    return count > 0 ? errorSum / count : double.infinity;
  }

  double _evaluateRegressor(Regressor regressor, List<HistorySeries> allSeries,
      [double lastSeriesWeight = 2]) {
    double totalError = 0;

    for (final series in allSeries) {
      double error = _computeMSE(regressor, series);
      if (series == allSeries.last) {
        error *= lastSeriesWeight;
      }
      totalError += error;
    }

    return totalError / allSeries.length;
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
        final firstLast = SpecificPointRegressor(0, points.length - 1, points);
        final secondLast = SpecificPointRegressor(1, points.length - 1, points);

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
        regressors.add(NormalizedRegressor.withBase(normalizer, firstLast, history.baseTimestamp,
            yShift: history.baseAmount));
        regressors.add(NormalizedRegressor.withBase(normalizer, secondLast, history.baseTimestamp,
            yShift: history.baseAmount));

      // final dataFrame = series.toDataFrame();
      // final dataFrameNormalizer = DataFrameNormalizer(dataFrame, 'amount');

      // Using the OLS Model
      // final olsRegressor = OLSRegressor();
      // olsRegressor.fit(dataFrameNormalizer.dataFrame, 'amount');
      // regressors.add(SimpleOLSRegressor(olsRegressor, dataFrameNormalizer));

      // Using the SGD Model
      // final sgdRegressor = LinearRegressor.SGD(dataFrame, 'amount',
      //     fitIntercept: true,
      //     interceptScale: .25,
      //     iterationLimit: 5000,
      //     initialLearningRate: 1,
      //     learningRateType: LearningRateType.constant);
      // regressors.add(MLLinearRegressor(sgdRegressor, dataFrameNormalizer));
    }

    return regressors;
  }
}
