import 'package:log/log.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';

class Evaluator {
  Map<String, Regressor> regressors = {};
  Map<String, double> accuracy = {};
  String _best = '';
  bool _trained = false;
  final String defaultType = 'Simple';
  History history;

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

  String get bestAccuracy {
    if (!_trained) {
      return '';
    }

    final bestRegressor = regressors[_best];
    if (_best.isEmpty || bestRegressor == null) {
      return '';
    }

    return '${accuracy[_best]!.toStringAsFixed(2)}%';
  }

  bool get trained => _trained;

  Map<String, double> allPredictions(double timestamp) {
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

  double predict(double timestamp) {
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
    // Update the history reference
    this.history = history;

    // Can't train on an empty history
    if (history.series.isEmpty) {
      return;
    }

    // First initialize the regressors
    regressors = _createRegressors();

    // Can't train if we have no regressors. This happens if we only
    // have one series with a single point.
    if (regressors.isEmpty) {
      return;
    }

    // Store the average accuracy of each regressor
    accuracy = _computeAccuracy();

    // Set the best regressor to the one with the highest accuracy
    // First sort the map, then take the last item
    accuracy =
        Map.fromEntries(accuracy.entries.toList()..sort((a, b) => a.value.compareTo(b.value)));
    _best = accuracy.keys.last;
    _trained = true;
  }

  Map<String, double> _computeAccuracy() {
    Map<String, double> accuracyMap = {};

    for (final regressorId in regressors.keys) {
      var regressor = regressors[regressorId]!;
      double totalAccuracy = 0;

      // Only compute accuracy for normalized regressors
      if (regressor is! NormalizedRegressor) {
        Log.w(
            'Regressor ${regressor.type} for upc ${history.upc} is not a NormalizedRegressor. Cannot evaluate.');
        continue;
      }

      for (final series in history.series) {
        double mape = _computeMAPE(regressor, series);
        double accuracy = 100 - mape;
        accuracy = accuracy.clamp(0, 100);
        totalAccuracy += accuracy;
      }

      double averageAccuracy = totalAccuracy / history.series.length;
      accuracyMap[regressorId] = averageAccuracy;
    }

    return accuracyMap;
  }

  double _computeMAPE(NormalizedRegressor regressor, HistorySeries series) {
    double errorSum = 0;
    int count = 0;

    final pointsMap = series.toPoints();

    // Save the original baseTimestamp and yShift
    double originalBaseTimestamp = regressor.baseTimestamp;
    double originalYShift = regressor.yShift;

    // Get the first data point and set it as baseTimestamp and yShift
    final firstEntry = pointsMap.entries.first;
    regressor.baseTimestamp = firstEntry.key;
    regressor.yShift = firstEntry.value;

    // Evaluate from the second point onwards
    for (final entry in pointsMap.entries.skip(1)) {
      final predictedValue = regressor.predict(entry.key);
      final trueValue = entry.value;

      // Avoid division by zero
      if (trueValue != 0) {
        final errorPercent = (trueValue - predictedValue).abs() / trueValue;
        errorSum += errorPercent;
        count++;
      }
    }

    // Restore the original baseTimestamp and yShift
    regressor.baseTimestamp = originalBaseTimestamp;
    regressor.yShift = originalYShift;

    // Convert to percentage
    double averageError = (count > 0 ? (errorSum / count) : 0) * 100;
    return averageError;
  }

  Map<String, Regressor> _createRegressors() {
    Map<String, Regressor> regressorMap = {};

    int seriesId = 0;
    for (final series in history.series) {
      var regressorList = _generateRegressors(series);

      for (final regressor in regressorList) {
        final regressorId = '${regressor.type}-$seriesId';
        regressorMap[regressorId] = regressor;
      }

      seriesId++;
    }

    return regressorMap;
  }

  // TwoPointLinearRegressor _createAverageRegressor(
  //     Map<int, double> points, List<Regressor> regressors) {
  //   List<double> slopes = regressors.map((regressor) => regressor.slope).toList();
  //   double averageSlope = slopes.reduce((a, b) => a + b) / slopes.length;

  //   int x1 = points.keys.first;
  //   double y1 = points.values.first;
  //   double intercept = y1 - averageSlope * x1;

  //   return TwoPointLinearRegressor(averageSlope, intercept);
  // }

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
        final holt = HoltLinearRegressor.fromMap(points, .9, .9);
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

      // final average = _createAverageRegressor(points, regressors);
      // regressors.add(NormalizedRegressor.withBase(normalizer, average, history.baseTimestamp,
      //     yShift: history.baseAmount));

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
