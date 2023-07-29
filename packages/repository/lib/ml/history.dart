import 'package:json_annotation/json_annotation.dart';
import 'package:repository/ml/evaluator.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';

part 'history.g.dart';

@JsonSerializable(explicitToJson: true)
class History {
  String upc = '';
  List<HistorySeries> series = [];

  @JsonKey(includeFromJson: false, includeToJson: false)
  late Evaluator evaluator;

  History() {
    evaluator = Evaluator(this);
  }

  factory History.fromJson(Map<String, dynamic> json) {
    final history = _$HistoryFromJson(json);
    history.evaluator.train(history);
    return history;
  }

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

  int get baseTimestamp {
    if (series.isEmpty) {
      return 0;
    }

    int value = 0;

    for (int i = series.length - 1; i >= 0; i--) {
      final individualSeries = series[i];

      if (individualSeries.observations.isNotEmpty) {
        final observation = individualSeries.observations.first;
        value = observation.timestamp.toInt();
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
      series.add(HistorySeries());
    }

    // There will always be at least one series
    // because we created it above if it doesn't exist
    return series.last;
  }

  Observation? get last {
    if (series.isEmpty) {
      return null;
    }

    return series.last.observations.lastOrNull;
  }

  DateTime get lastTimestamp {
    if (series.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
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

  int get predictedOutageTimestamp {
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
  void add(int timestamp, double amount, int householdCount, {int minOffsetHours = 24}) {
    assert(timestamp != 0); // Timestamp cannot be a placeholder value

    clean();

    // There is not any point in making a HistorySeries where the only
    // entry is 0. We can't use a single 0 value for prediction purposes.
    // Do not add the value under these circumstances.
    if (current.observations.isEmpty && amount == 0) {
      return;
    }

    // Create a new observation
    var observation = Observation(
      timestamp: timestamp.toDouble(),
      amount: amount,
      householdCount: householdCount,
    );

    // If the series is empty, start a new series
    if (series.isEmpty) {
      series.add(HistorySeries());
    }

    // Check if current.observations is empty. If so, we only need
    // to add the single non-zero value.
    if (current.observations.isEmpty) {
      current.observations.add(observation);
      return;
    }

    // Get the last observation in the current series
    var lastObservation = current.observations.last;

    // Calculate the time difference between the new observation and the last one
    var timeDifference = observation.timestamp - lastObservation.timestamp;

    // Define the minimum time offset in ms (specified by minOffsetHours)
    final minOffset = minOffsetHours * 60 * 60 * 1000;

    if (timeDifference < minOffset) {
      if (observation.amount > lastObservation.amount && series.length > 1) {
        // If this is an increase and this is not the only item in the
        // series, start a new series and add the new observation
        series.add(HistorySeries());
        current.observations.add(observation);
      } else {
        // If it's a decrease or the current item is the only one in the
        // series, simply update the last observation's amount
        current.observations.removeLast();
        current.observations.add(observation);
      }
    }

    // Otherwise, add the new observation as usual
    else {
      // If the new observation's amount is greater than the last one,
      // start a new series and add the new observation
      if (observation.amount > lastObservation.amount) {
        // If the predicted outage timestamp is earlier than the new timestamp, add a zero amount observation
        if (predictedOutageTimestamp < timestamp) {
          current.observations.add(Observation(
            timestamp: predictedOutageTimestamp.toDouble(),
            amount: 0,
            householdCount: householdCount,
          ));
        }

        // Start a new series
        series.add(HistorySeries());
        current.observations.add(observation);
      }

      // If the new observation's amount is the same as the last one, do nothing

      // If the new observation's amount is less than the last one, add the new observation
      else if (observation.amount < lastObservation.amount) {
        // If the new observation's amount is zero and the predicted outage timestamp is earlier than the new timestamp,
        // add a zero amount observation
        if (observation.amount == 0 && canPredict && predictedOutageTimestamp < timestamp) {
          current.observations.add(Observation(
            timestamp: predictedOutageTimestamp.toDouble(),
            amount: 0,
            householdCount: householdCount,
          ));
        } else {
          current.observations.add(observation);
        }
      }
    }

    // We added a new decrease, and we have more than one observation
    if (observation.amount < lastObservation.amount && current.observations.length > 1) {
      evaluator.train(this);
      evaluator.assess(observation);
    }
  }

  // Remove any invalid observations from the history
  // (This means any series where there is only a 0 value,
  // or the timestamp is 0)
  History clean() {
    for (final s in series) {
      // There was only one observation with amount 0, so remove it
      if (s.observations.length == 1 && s.observations.first.amount == 0) {
        s.observations.clear();
      }
      // Remove any observations with placeholder timestamps
      else {
        s.observations.removeWhere((o) => o.timestamp == 0);
      }

      // Ensure that every item is decreasing, and remove duplicates
      int i = 0;
      while (i < s.observations.length - 1) {
        // Check boundary before accessing
        if (i + 1 < s.observations.length) {
          // Remove if current observation has increased from the last one
          if (s.observations[i].amount < s.observations[i + 1].amount) {
            s.observations.removeAt(i + 1);
            continue;
          } else if (s.observations[i].amount == s.observations[i + 1].amount) {
            // Remove any duplicate observations
            s.observations.removeAt(i + 1);
            continue;
          } else {
            i++; // Only move forward if we did not remove an item
          }
        }
      }
    }

    trim();
    return this;
  }

  bool equalTo(History other) =>
      identical(this, other) || upc == other.upc && series.equals(other.series);

  History merge(History other) {
    assert(upc == other.upc);

    // Create a new merged History instance
    History merged = History();
    merged.upc = upc;

    // Create a map of all the history series from both History instances,
    // using the HistorySeries minTimestamp as the key
    Map<int, HistorySeries> thisSeriesMap = {for (var s in series) s.minTimestamp: s};
    Map<int, HistorySeries> otherSeriesMap = {for (var s in other.series) s.minTimestamp: s};

    // Get all unique minTimestamp keys
    Set<int> allKeys = {};
    allKeys.addAll(thisSeriesMap.keys);
    allKeys.addAll(otherSeriesMap.keys);

    // For each unique key, merge the corresponding HistorySeries from both History instances
    for (final key in allKeys) {
      HistorySeries? thisSeries = thisSeriesMap[key];
      HistorySeries? otherSeries = otherSeriesMap[key];

      if (thisSeries != null && otherSeries != null) {
        // If both History instances have a HistorySeries with this minTimestamp,
        // choose the one with the higher maxTimestamp since it
        // has been updated more recently
        if (thisSeries.maxTimestamp > otherSeries.maxTimestamp) {
          merged.series.add(thisSeries);
        } else {
          merged.series.add(otherSeries);
        }
      } else if (thisSeries != null) {
        // If only this History instance has a HistorySeries with this minTimestamp, add it
        merged.series.add(thisSeries);
      } else if (otherSeries != null) {
        // If only the other History instance has a HistorySeries with this minTimestamp, add it
        merged.series.add(otherSeries);
      }
    }

    return merged;
  }

  double predict(int timestamp) {
    if (!evaluator.trained) {
      evaluator.train(this);
    }

    return evaluator.predict(timestamp);
  }

  Map<String, dynamic> toJson() => _$HistoryToJson(this);

  // Remove any empty series values in the history
  History trim() {
    series.removeWhere((s) => s.observations.isEmpty);
    return this;
  }
}
