import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:repository/ml/observation.dart';

part 'history_series.g.dart';

@JsonSerializable(explicitToJson: true)
class HistorySeries {
  List<Observation> observations = [];
  HistorySeries();

  List<Observation> get normalizedObservations {
    if (observations.isEmpty) {
      return [];
    }

    double initialTimestamp = observations[0].timestamp;
    double initialAmount = observations[0].amount;
    return observations
        .map((o) => Observation(
              timestamp: o.timestamp - initialTimestamp,
              amount: o.amount / initialAmount,
              householdCount: o.householdCount,
            ))
        .toList();
  }

  int get minTimestamp {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.timestamp.toInt()).reduce(min);
  }

  int get maxTimestamp {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.timestamp.toInt()).reduce(max);
  }

  double get minAmount {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.amount).reduce(min);
  }

  double get maxAmount {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.amount).reduce(max);
  }

  double getAbsoluteAmount(double relativeAmount) {
    return relativeAmount * maxAmount;
  }

  int getAbsoluteTimestamp(int relativeTimestamp) {
    return relativeTimestamp + minTimestamp;
  }

  int getRelativeTimestamp(double scaledTimestamp) {
    return (scaledTimestamp * (maxTimestamp - minTimestamp)).toInt();
  }

  factory HistorySeries.fromJson(Map<String, dynamic> json) => _$HistorySeriesFromJson(json);
  Map<String, dynamic> toJson() => _$HistorySeriesToJson(this);

  DataFrame toDataFrame() {
    final data = observations.map((o) => o.toList()).toList();
    return DataFrame(data, headerExists: false, header: Observation.header);
  }

  Map<int, double> toPoints() {
    return observations.fold({}, (map, o) {
      map[o.timestamp.toInt()] = o.amount;
      return map;
    });
  }
}
