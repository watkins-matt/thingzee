import 'dart:math';

import 'package:kmeans_cluster/kmeans.dart';
import 'package:log/log.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';
import 'package:util/extension/list.dart';

class Evaluator {
  Map<String, Regressor> regressors = {};
  Map<String, double> accuracy = {};
  Map<String, double> latestAccuracy = {};
  Map<String, double> clusterAccuracy = {};
  KMeansClusterer clusterer = KMeansClusterer({});

  /// Holds the indices of series considered to be outliers.
  Set<int> outlierSeriesIndices = {};
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

  /// Returns a cluster that represents an aggregation of all
  /// regressors that are most similar to the recent trend.
  Cluster? get mostRecentCluster {
    int seriesCount = history.series.length;

    // Go backwards through the series list to find the
    // first one represented in a cluster
    for (int index = seriesCount - 1; index >= 0; index--) {
      Cluster? current = clusterer['$index'];

      if (current != null) {
        return current;
      }
    }

    return null;
  }

  bool get trained => _trained;

  // Contains the indices of series are most similar to recent data.
  Set<int> get trendingSeries {
    final recentCluster = mostRecentCluster;
    return recentCluster != null
        ? recentCluster.members.map((member) => int.parse(member)).toSet()
        : <int>{};
  }

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

  /// Clusters the series data to identify similar trends
  void cluster() {
    final seriesUsageRateDays = <String, double>{};

    // Iterate over each series to find the median usageRateDays
    for (int i = 0; i < history.series.length; i++) {
      var regressorsForSeries = _getRegressorsForSeries(i);

      // Extract the usageRateDays for the series
      var usageRateDaysList = regressorsForSeries
          .whereType<NormalizedRegressor>()
          .map((regressor) => regressor.usageRateDays)
          .toList();

      if (usageRateDaysList.isNotEmpty) {
        // Calculate the median usageRateDays for the series
        double medianUsageRateDays = usageRateDaysList.median;
        seriesUsageRateDays['$i'] = medianUsageRateDays;
      }
    }

    // Cluster each series based on the median usageRateDays
    clusterer = KMeansClusterer(seriesUsageRateDays);
    clusterer.cluster();
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

    double result = best.predict(timestamp);

    // If we don't have any observations, we can't compare to the
    // latest value, so we just return the result.
    if (history.current.observations.isEmpty) {
      return result;
    }

    // Check to see what the most recent value is to compare with our prediction
    double latestValue = history.current.observations.last.amount;

    // If the predicted value is more than 50% greater than the latest value,
    // there is likely something wrong with the prediction.
    if (result > (latestValue * 1.5)) {
      Log.w('Predicted value for upc ${history.upc} is more '
          'than 150% greater than the latest value. '
          'Predicted: $result, Latest: $latestValue');
    }

    // If the user put a value in the app, we should not predict
    // a value that is greater than the user's value.
    return min(result, latestValue);
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

    // Cluster the regressors
    cluster();

    // Update the accuracy and latestAccuracy maps
    _updateAccuracy();

    // Update the cluster accuracy map
    _updateClusterAccuracy();

    // Note that we sort the accuracy maps within _updateAccuracy and
    // _updateClusterAccuracy, so the last entry in each map is the best

    // Set the best regressor the the one with the highest accuracy
    // if there is only 1 data point in the last series, otherwise set
    // it to whichever regressor has the highest accuracy on the latest data
    // point.
    if (clusterAccuracy.isNotEmpty) {
      double bestClusterAccuracy = clusterAccuracy.values.last;
      if (bestClusterAccuracy > latestAccuracy.values.last) {
        _best = clusterAccuracy.keys.last;
      } else {
        _best = latestAccuracy.keys.last;
      }
    } else if (history.series.isNotEmpty && history.series.last.observations.length == 1) {
      _best = accuracy.keys.last;
    } else {
      _best = latestAccuracy.keys.last;
    }

    _trained = true;
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

  double _computeMAPE(NormalizedRegressor regressor, HistorySeries series) {
    double errorSum = 0;
    int count = 0;

    final pointsMap = series.toPoints();

    // Save the original baseTimestamp and yScale
    double originalBaseTimestamp = regressor.baseTimestamp;
    double originalYScale = regressor.yScale;

    // Get the first data point and set it as baseTimestamp and yScale
    final firstEntry = pointsMap.entries.first;
    regressor.baseTimestamp = firstEntry.key;
    regressor.yScale = firstEntry.value;

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

    // Restore the original baseTimestamp and yScale
    regressor.baseTimestamp = originalBaseTimestamp;
    regressor.yScale = originalYScale;

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

  List<Regressor> _generateRegressors(HistorySeries series) {
    List<Regressor> regressors = [];

    switch (series.observations.length) {
      case 0:
      case 1:
        return [];
      case 2:
        var points = series.toPoints();

        var x1 = points.keys.elementAt(0);
        var y1 = points.values.elementAt(0);
        var x2 = points.keys.elementAt(1);
        var y2 = points.values.elementAt(1);

        final regressor = TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2);

        return [
          NormalizedRegressor(regressor, points,
              baseTimestamp: history.baseTimestamp, yScale: history.baseAmount)
        ];
      default:
        var points = series.toPoints();
        final simple = SimpleLinearRegressor(points);
        final naive = NaiveRegressor.fromMap(points);
        final holt = HoltLinearRegressor.fromMap(points, 0.75, 0.15);
        final shifted = ShiftedInterceptLinearRegressor(points);
        final weighted = WeightedLeastSquaresLinearRegressor(points);
        final firstLast = SpecificPointRegressor(0, points.length - 1, points);
        final secondLast = SpecificPointRegressor(1, points.length - 1, points);

        regressors.add(NormalizedRegressor(simple, points,
            baseTimestamp: history.baseTimestamp, yScale: history.baseAmount));
        regressors.add(NormalizedRegressor(naive, points,
            baseTimestamp: history.baseTimestamp,
            yScale: history.baseAmount,
            startIndex: points.length - 2,
            endIndex: points.length - 1));
        regressors.add(NormalizedRegressor(holt, points,
            baseTimestamp: history.baseTimestamp, yScale: history.baseAmount));
        regressors.add(NormalizedRegressor(shifted, points,
            baseTimestamp: history.baseTimestamp, yScale: history.baseAmount));
        regressors.add(NormalizedRegressor(weighted, points,
            baseTimestamp: history.baseTimestamp, yScale: history.baseAmount));
        regressors.add(NormalizedRegressor(firstLast, points,
            baseTimestamp: history.baseTimestamp,
            yScale: history.baseAmount,
            startIndex: 0,
            endIndex: points.length - 1));
        regressors.add(NormalizedRegressor(secondLast, points,
            baseTimestamp: history.baseTimestamp,
            yScale: history.baseAmount,
            startIndex: 1,
            endIndex: points.length - 1));

      // final average = _createAverageRegressor(points, regressors);
      // regressors.add(NormalizedRegressor.withBase(normalizer, average, history.baseTimestamp,
      //     yScale: history.baseAmount));

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

  /// Retrieves regressors corresponding to a series index.
  List<Regressor> _getRegressorsForSeries(int seriesIndex) {
    final pattern = '-$seriesIndex';
    return regressors.entries
        .where((entry) => entry.key.endsWith(pattern))
        .map((entry) => entry.value)
        .toList();
  }

  void _updateAccuracy() {
    for (final regressorId in regressors.keys) {
      var regressor = regressors[regressorId]!;
      double totalAccuracy = 0;
      int seriesCount = 0;

      // Only compute accuracy for normalized regressors
      if (regressor is! NormalizedRegressor) {
        Log.w(
            'Regressor ${regressor.type} for upc ${history.upc} is not a NormalizedRegressor. Cannot evaluate.');
        continue;
      }

      // Last series is the most recent one with > 1 data point
      int lastSeriesIndex = history.series.length - 1;
      while (lastSeriesIndex >= 0 && history.series[lastSeriesIndex].observations.length <= 1) {
        lastSeriesIndex--;
      }

      for (int i = 0; i < history.series.length; i++) {
        final series = history.series[i];

        // Skip outlier series
        if (outlierSeriesIndices.contains(i)) {
          continue;
        }

        double mape = _computeMAPE(regressor, series);
        double accuracy = 100 - mape;
        accuracy = accuracy.clamp(0, 100);
        totalAccuracy += accuracy;
        seriesCount++;

        // Store the latest accuracy for each regressor
        if (i == lastSeriesIndex) {
          // Penalize regressors by 20% if they originated with the same
          // series to avoid overfitting
          if (regressorId.endsWith('-$i')) {
            accuracy *= .8;
          }

          latestAccuracy[regressorId] = accuracy;
        }
      }

      double averageAccuracy = (seriesCount > 0) ? totalAccuracy / seriesCount : 0;
      accuracy[regressorId] = averageAccuracy;
    }

    accuracy =
        Map.fromEntries(accuracy.entries.toList()..sort((a, b) => a.value.compareTo(b.value)));
    latestAccuracy = Map.fromEntries(
        latestAccuracy.entries.toList()..sort((a, b) => a.value.compareTo(b.value)));
  }

  /// Calculates the accuracy for regressors based on the series in the mostRecentCluster.
  void _updateClusterAccuracy() {
    final Set<int> trendingSeriesIndices = trendingSeries;
    clusterAccuracy.clear();

    for (final entry in regressors.entries) {
      final regressorId = entry.key;
      final regressor = entry.value;

      // Only consider normalized regressors
      if (regressor is! NormalizedRegressor) continue;

      double totalAccuracy = 0;
      int count = 0;

      // Compute the accuracy for each trending series
      for (final seriesIndex in trendingSeriesIndices) {
        final series = history.series[seriesIndex];

        // Skip outlier series
        if (outlierSeriesIndices.contains(seriesIndex)) continue;

        double mape = _computeMAPE(regressor, series);
        double accuracy = 100 - mape;
        totalAccuracy += accuracy.clamp(0, 100);
        count++;
      }

      // Calculate and store the average accuracy for the regressor
      if (count > 0) {
        double averageAccuracy = totalAccuracy / count;
        clusterAccuracy[regressorId] = averageAccuracy;
      }
    }

    // Sort the map by accuracy
    clusterAccuracy = Map.fromEntries(
        clusterAccuracy.entries.toList()..sort((a, b) => a.value.compareTo(b.value)));
  }
}
