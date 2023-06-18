import 'package:json_annotation/json_annotation.dart';
import 'package:repository/ml/evaluator.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';

part 'history.g.dart';

@JsonSerializable(explicitToJson: true)
class History {
  String upc = '';
  List<HistorySeries> allSeries = [];
  late Evaluator evaluator;
  History() {
    evaluator = Evaluator(this);
  }

  factory History.fromJson(Map<String, dynamic> json) => _$HistoryFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryToJson(this);

  bool get canPredict {
    return regressor.hasXIntercept;
  }

  Regressor get regressor {
    return evaluator.best;
  }

  HistorySeries get current {
    if (allSeries.isEmpty) {
      allSeries.add(HistorySeries());
    }

    // There will always be at least one series
    // because we created it above if it doesn't exist
    return allSeries.last;
  }

  int get predictedOutageTimestamp {
    return regressor.xIntercept;
  }

  HistorySeries get previous {
    return allSeries.length > 1 ? allSeries[allSeries.length - 2] : current;
  }

  int get totalPoints {
    return allSeries.fold(0, (sum, s) => sum + s.observations.length);
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
    if (allSeries.isEmpty) {
      allSeries.add(HistorySeries());
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

    // If the time difference is less than the minimum offset, update the last observation
    if (timeDifference < minOffset) {
      current.observations.removeLast();
      current.observations.add(observation);
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
        allSeries.add(HistorySeries());
        current.observations.add(observation);
      }

      // If the new observation's amount is the same as the last one, do nothing

      // If the new observation's amount is less than the last one, add the new observation
      else if (observation.amount < lastObservation.amount) {
        // If the new observation's amount is zero and the predicted outage timestamp is earlier than the new timestamp,
        // add a zero amount observation
        if (observation.amount == 0 && predictedOutageTimestamp < timestamp) {
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

    evaluator.assess(observation);
    evaluator.train(this);
  }

  // Remove any invalid observations from the history
  // (This means any series where there is only a 0 value,
  // or the timestamp is 0)
  History clean() {
    for (final s in allSeries) {
      // There was only one observation with amount 0, so remove it
      if (s.observations.length == 1 && s.observations.first.amount == 0) {
        s.observations.clear();
      }
      // Remove any observations with placeholder timestamps
      else {
        s.observations.removeWhere((o) => o.timestamp == 0);
      }
    }

    trim();
    return this;
  }

  List<Observation> get normalizedObservations {
    return allSeries.expand((s) {
      double initialTimestamp = s.observations[0].timestamp;
      double initialAmount = s.observations[0].amount;
      return s.observations.map((o) => Observation(
            timestamp: o.timestamp - initialTimestamp,
            amount: o.amount / initialAmount,
            householdCount: o.householdCount,
          ));
    }).toList();
  }

  double predict(int timestamp) {
    if (!evaluator.trained) {
      evaluator.train(this);
    }

    return evaluator.predict(timestamp);
  }

  // Remove any empty series values in the history
  History trim() {
    allSeries.removeWhere((s) => s.observations.isEmpty);
    return this;
  }
}
