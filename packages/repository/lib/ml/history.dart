import 'package:json_annotation/json_annotation.dart';
import 'package:log/log.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/date_time.dart';
import 'package:repository/ml/evaluator.dart';
import 'package:repository/ml/evaluator_provider.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'history.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class History extends Model<History> {
  final String upc;
  final List<HistorySeries> series;

  History({
    this.upc = '',
    this.series = const [],
    super.created,
    super.updated,
  });

  factory History.fromJson(Map<String, dynamic> json) => _$HistoryFromJson(json);

  double get baseAmount {
    if (series.isEmpty) {
      return 0;
    }

    double value = 0;

    for (int i = series.length - 1; i >= 0; i--) {
      final individualSeries = series[i];

      if (individualSeries.observations.isNotEmpty) {
        final observation = individualSeries.observations.first;
        value = observation.amount;
        break;
      }
    }

    return value;
  }

  double get baseTimestamp {
    if (series.isEmpty) {
      return 0;
    }

    double value = 0;

    for (int i = series.length - 1; i >= 0; i--) {
      final individualSeries = series[i];

      if (individualSeries.observations.isNotEmpty) {
        final observation = individualSeries.observations.first;
        value = observation.timestamp;
        break;
      }
    }

    return value;
  }

  bool get canPredict {
    return regressor.hasXIntercept;
  }

  HistorySeries get current {
    if (series.isEmpty) {
      return HistorySeries(); // Return a new empty series
    }

    return series.last; // Return the last series
  }

  Evaluator get evaluator {
    return EvaluatorProvider().getEvaluator(upc, this);
  }

  @override
  String get id => upc;

  Observation? get last {
    if (series.isEmpty) {
      return null;
    }

    return series.last.observations.lastOrNull;
  }

  DateTime? get lastTimestamp {
    if (series.isEmpty || series.last.observations.isEmpty) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(series.last.observations.last.timestamp.toInt());
  }

  List<Observation> get normalizedObservations {
    return series.expand((s) {
      double initialTimestamp = s.observations[0].timestamp;
      double initialAmount = s.observations[0].amount;
      return s.observations.map((o) => Observation(
            timestamp: o.timestamp - initialTimestamp,
            amount: o.amount / initialAmount,
            householdCount: o.householdCount,
          ));
    }).toList();
  }

  double get predictedOutageTimestamp {
    return regressor.xIntercept;
  }

  HistorySeries get previous {
    return series.length > 1 ? series[series.length - 2] : current;
  }

  Regressor get regressor {
    return evaluator.best;
  }

  int get totalPoints {
    return series.fold(0, (sum, s) => sum + s.observations.length);
  }

  @override
  DateTime? get updated {
    return lastTimestamp ?? super.updated;
  }

  /// Adds a new data point to the history series.
  /// [timestamp] represents the time of the data point in milliseconds since epoch. This value cannot be zero.
  /// [amount] represents the amount of inventory.
  /// [householdCount] represents the number of people living in the household.
  /// Requirements:
  /// - Function will fail if [timestamp] is zero.
  /// - We only care about decreasing values. If the series is empty,
  ///   a single zero amount will be discarded.
  /// - Create a new series if necessary.
  /// - If this is a new series, add the new data point and return.
  /// - If the amount is within the minimum offset, we update the timestamp only.
  /// - If the amount is greater than the last amount, start a new series
  ///     and add the new data point.
  /// - If the amount was decreased add the amount.
  /// - If we predicted the amount to be 0 before the user set it to zero,
  ///     choose the predicted timestamp as the timestamp, assuming that
  ///     the user likely updated the amount after the fact.
  History add(int timestamp, double amount, int householdCount, {int minOffsetHours = 24}) {
    assert(timestamp != 0); // Timestamp cannot be a placeholder value

    // Clean the history first
    History updatedHistory = clean(warn: true);

    // There is not any point in making a HistorySeries where the only
    // entry is 0. We can't use a single 0 value for prediction purposes.
    // Do not add the value under these circumstances.
    if (updatedHistory.current.observations.isEmpty && amount == 0) {
      return updatedHistory;
    }

    // Create a new observation
    var observation = Observation(
      timestamp: timestamp.toDouble(),
      amount: amount,
      householdCount: householdCount,
    );

    // Copy the series list to modify
    List<HistorySeries> updatedSeries = List.from(updatedHistory.series);

    // If the series is empty, start a new series
    if (updatedSeries.isEmpty) {
      updatedSeries.add(HistorySeries());
    }

    var currentSeries = updatedSeries.last;

    // Check if currentSeries observations is empty. If so, we only need
    // to add the single non-zero value.
    if (currentSeries.observations.isEmpty) {
      currentSeries.observations.add(observation);
      return updatedHistory.copyWith(series: updatedSeries);
    }

    // Get the last observation in the current series
    var lastObservation = currentSeries.observations.last;

    // Calculate the time difference between the new observation and the last one
    var timeDifference = observation.timestamp - lastObservation.timestamp;

    // Define the minimum time offset in ms (specified by minOffsetHours)
    final minOffset = minOffsetHours * 60 * 60 * 1000;

    if (timeDifference < minOffset) {
      if (observation.amount > lastObservation.amount && updatedSeries.length > 1) {
        // If this is an increase and this is not the only item in the
        // series, start a new series and add the new observation
        updatedSeries.add(HistorySeries());
        updatedSeries.last.observations.add(observation);
      } else {
        // If it's a decrease or the current item is the only one in the
        // series, simply update the last observation's amount
        currentSeries.observations.removeLast();
        currentSeries.observations.add(observation);
      }
    }
    // Otherwise, add the new observation as usual
    else {
      // If the new observation's amount is greater than the last one,
      // start a new series and add the new observation
      if (observation.amount > lastObservation.amount) {
        // If the predicted outage timestamp is earlier than the new timestamp, add a zero amount observation
        if (updatedHistory.predictedOutageTimestamp < timestamp) {
          currentSeries.observations.add(Observation(
            timestamp: updatedHistory.predictedOutageTimestamp.toDouble(),
            amount: 0,
            householdCount: householdCount,
          ));
        }
        // Start a new series
        updatedSeries.add(HistorySeries());
        updatedSeries.last.observations.add(observation);
      }
      // If the new observation's amount is the same as the last one, do nothing

      // If the new observation's amount is less than the last one, add the new observation

      else if (observation.amount < lastObservation.amount) {
        // If the new observation's amount is zero and the predicted outage timestamp is earlier than the new timestamp,
        // add a zero amount observation
        if (observation.amount == 0 &&
            updatedHistory.canPredict &&
            updatedHistory.predictedOutageTimestamp < timestamp) {
          currentSeries.observations.add(Observation(
            timestamp: updatedHistory.predictedOutageTimestamp.toDouble(),
            amount: 0,
            householdCount: householdCount,
          ));
        } else {
          currentSeries.observations.add(observation);
        }
      }
    }

    // Return a new History instance with the updated series
    return updatedHistory.copyWith(series: updatedSeries);
  }

  // Remove any invalid observations from the history
  // (This means any series where there is only a 0 value,
  // or the timestamp is 0)
  History clean({bool warn = false}) {
    List<HistorySeries> updatedSeries = List.from(series);

    for (final s in updatedSeries) {
      // There was only one observation, and this is not the last series
      if (s.observations.length == 1 && (last != null && s.observations.last != last)) {
        s.observations.clear();
        if (warn) Log.w('Removed single empty observation from history series $upc.');
      }
      // Remove any observations with placeholder timestamps
      else {
        int originalCount = s.observations.length;
        s.observations.removeWhere((o) => o.timestamp == 0);
        if (originalCount > s.observations.length && warn) {
          Log.w('Removed observation with invalid timestamp from history series $upc.');
        }
      }

      // Ensure that every item is decreasing, and remove duplicates
      int i = 0;
      while (i < s.observations.length - 1) {
        // Check boundary before accessing
        if (i + 1 < s.observations.length) {
          // Remove if current observation has increased from the last one
          if (s.observations[i].amount < s.observations[i + 1].amount) {
            s.observations.removeAt(i + 1);
            if (warn) Log.w('Removed invalid increasing observation from history series $upc.');
            continue;
          } else if (s.observations[i].amount == s.observations[i + 1].amount) {
            // Remove any duplicate observations
            s.observations.removeAt(i + 1);
            if (warn) Log.w('Removed duplicate observation from history series $upc.');
            continue;
          } else {
            i++; // Only move forward if we did not remove an item
          }
        }
      }
    }

    // Create a new instance with the updated series
    return History(upc: upc, series: updatedSeries, created: created, updated: updated).trim();
  }

  @override
  History copyWith({
    String? upc,
    List<HistorySeries>? series,
    DateTime? created,
    DateTime? updated,
  }) {
    return History(
      upc: upc ?? this.upc,
      series: series ?? this.series,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  History delete(int seriesIndex) {
    if (seriesIndex < 0 || seriesIndex >= series.length) {
      throw ArgumentError('Series index out of bounds');
    }
    List<HistorySeries> updatedSeries = List.from(series)..removeAt(seriesIndex);
    return copyWith(series: updatedSeries);
  }

  @override
  bool equalTo(History other) =>
      identical(this, other) || upc == other.upc && series.equals(other.series);

  @override
  History merge(History other) {
    assert(upc == other.upc);

    // Combine series from both instances, filtering out series without observations
    List<HistorySeries> allSeries = series.where((s) => s.observations.isNotEmpty).toList()
      ..addAll(other.series.where((s) => s.observations.isNotEmpty));

    // Group series by minTimestamp and choose the one with the highest maxTimestamp for each group
    final Map<int, HistorySeries> mergedSeriesMap = {};
    for (final series in allSeries) {
      final existingSeries = mergedSeriesMap[series.minTimestamp];
      if (existingSeries == null || series.maxTimestamp > existingSeries.maxTimestamp) {
        mergedSeriesMap[series.minTimestamp] = series.copy();
      }
    }

    // Set the merged series to the sorted values of the map
    List<HistorySeries> mergedSeries = mergedSeriesMap.values.toList()
      ..sort((a, b) => a.minTimestamp.compareTo(b.minTimestamp));

    return History(
      upc: upc,
      series: mergedSeries,
      created: created.older(other.created),
      updated: DateTime.now(), // Updated time is now, as it's a new merged entity
    );
  }

  double predict(double timestamp) {
    return evaluator.predict(timestamp);
  }

  @override
  Map<String, dynamic> toJson() => _$HistoryToJson(this);

  // Remove any empty series values in the history
  History trim() {
    List<HistorySeries> trimmedSeries = series.where((s) => s.observations.isNotEmpty).toList();
    return copyWith(series: trimmedSeries);
  }
}
