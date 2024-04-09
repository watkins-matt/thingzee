import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:repository/ml/observation.dart';
import 'package:util/extension/list.dart';

part 'history_series.g.dart';

@JsonSerializable(explicitToJson: true)
class HistorySeries {
  List<Observation> observations = [];
  HistorySeries();

  factory HistorySeries.fromJson(Map<String, dynamic> json) => _$HistorySeriesFromJson(json);

  double get maxAmount {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.amount).reduce(max);
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

  int get minTimestamp {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.timestamp.toInt()).reduce(min);
  }

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

  HistorySeries copy() {
    return HistorySeries()..observations = observations.map((o) => o.copy()).toList();
  }

  HistorySeries copyWith({List<Observation>? observations}) {
    return HistorySeries()
      ..observations = observations ?? this.observations.map((o) => o.copy()).toList();
  }

  bool equalTo(Object other) =>
      identical(this, other) ||
      other is HistorySeries &&
          runtimeType == other.runtimeType &&
          observations.equals(other.observations);

  double getAbsoluteAmount(double relativeAmount) {
    return relativeAmount * maxAmount;
  }

  int getAbsoluteTimestamp(int relativeTimestamp) {
    return relativeTimestamp + minTimestamp;
  }

  int getRelativeTimestamp(double scaledTimestamp) {
    return (scaledTimestamp * (maxTimestamp - minTimestamp)).toInt();
  }

  DataFrame toDataFrame() {
    final data = observations.map((o) => o.toList()).toList();
    return DataFrame(data, headerExists: false, header: Observation.header);
  }

  Map<String, dynamic> toJson() => _$HistorySeriesToJson(this);

  Map<double, double> toPoints() {
    return observations.fold({}, (map, o) {
      map[o.timestamp] = o.amount;
      return map;
    });
  }
}

extension HistoryList<T> on List<HistorySeries> {
  bool equals(List<T> other) {
    if (identical(this, other)) return true;
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (!this[i].equalTo(other[i]!)) return false;
    }
    return true;
  }
}
