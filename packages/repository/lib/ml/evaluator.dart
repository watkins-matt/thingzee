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

  bool get trained => _trained;

  int get _baseTimestamp {
    if (history.allSeries.isEmpty) {
      return 0;
    }

    for (int i = history.allSeries.length - 1; i >= 0; i--) {
      final series = history.allSeries[i];

      if (series.observations.isNotEmpty) {
        return series.observations.first.timestamp.toInt();
      }
    }

    return 0;
  }

  double get _baseAmount {
    if (history.allSeries.isEmpty) {
      return 0;
    }

    for (int i = history.allSeries.length - 1; i >= 0; i--) {
      final series = history.allSeries[i];

      if (series.observations.isNotEmpty) {
        return series.observations.first.amount;
      }
    }

    return 0;
  }

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

    // If there is any series with a length greater than one
    // then the best regressor should not be an EmptyRegressor
    if (history.allSeries.any((s) => s.observations.length > 1)) {
      assert(_best.type != 'Empty' && _best.type != 'SinglePoint');
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

    var normTimestamp = timestamp - _baseTimestamp;
    var normAmount = _baseAmount;

    return best.predict(normTimestamp) * normAmount;
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
        var points = series.toPoints();
        MapNormalizer normalizer = MapNormalizer(points);
        points = normalizer.dataPoints;

        var x1 = points.keys.elementAt(0);
        var y1 = points.values.elementAt(0);
        var x2 = points.keys.elementAt(1);
        var y2 = points.values.elementAt(1);

        return [TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2)];
      default:
        var points = series.toPoints();
        MapNormalizer normalizer = MapNormalizer(points);
        points = normalizer.dataPoints;

        final simple = SimpleLinearRegressor(points);
        final naive = NaiveRegressor.fromMap(points);
        final holt = HoltLinearRegressor.fromMap(points, .85, .75);
        final shifted = ShiftedInterceptLinearRegressor(points);
        final weighted = WeightedLeastSquaresLinearRegressor(points);

        regressors.add(simple);
        regressors.add(naive);
        regressors.add(holt);
        regressors.add(shifted);
        regressors.add(weighted);

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
