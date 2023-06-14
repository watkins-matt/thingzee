import 'package:json_annotation/json_annotation.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/observation.dart';

part 'ml_history.g.dart';

@JsonSerializable(explicitToJson: true)
class MLHistory {
  String upc = '';
  List<HistorySeries> series = [];
  MLHistory();

  factory MLHistory.fromJson(Map<String, dynamic> json) => _$MLHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$MLHistoryToJson(this);

  HistorySeries get best {
    return canPredict ? current : previous;
  }

  bool get canPredict {
    return current.regressor.hasXIntercept || previous.regressor.hasXIntercept;
  }

  HistorySeries get current {
    if (series.isEmpty) {
      series.add(HistorySeries());
    }

    // There will always be at least one series
    // because we created it above if it doesn't exist
    return series.last;
  }

  int get predictedOutageTimestamp {
    return best.regressor.xIntercept;
  }

  HistorySeries get previous {
    return series.length > 1 ? series[series.length - 2] : current;
  }

  int get totalPoints {
    return series.fold(0, (sum, s) => sum + s.observations.length);
  }

  void add(int timestamp, double amount, int householdCount) {
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
    if (series.isEmpty) {
      series.add(HistorySeries());
      current.observations.add(observation);
      return;
    }

    // Check if current.observations is empty, if yes then add the observation and return
    if (current.observations.isEmpty) {
      current.observations.add(observation);
      return;
    }

    // Get the last observation in the current series
    var lastObservation = current.observations.last;

    // Calculate the time difference between the new observation and the last one
    var timeDifference = observation.timestamp - lastObservation.timestamp;

    // Define the minimum time offset (24 hours in milliseconds)
    const minOffset = 24 * 60 * 60 * 1000;

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
        series.add(HistorySeries());
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
  }

  // Remove any invalid observations from the history
  // (This means any series where there is only a 0 value,
  // or the timestamp is 0)
  MLHistory clean() {
    for (final s in series) {
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

  double predict(int timestamp) {
    // Note that if this series is empty, it will predict based on the last series
    return best.regressor.predict(timestamp);
  }

  // Remove any empty series values in the history
  MLHistory trim() {
    series.removeWhere((s) => s.observations.isEmpty);
    return this;
  }
}
