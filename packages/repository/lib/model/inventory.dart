import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:repository/extension/duration.dart';
import 'package:repository/ml/history.dart';
import 'package:stats/double.dart';

part 'inventory.g.dart';

@JsonSerializable(explicitToJson: true)
class Inventory {
  double amount = 0;
  int unitCount = 1;
  @OptDateTimeSerializer()
  DateTime? lastUpdate;
  List<DateTime> expirationDates = <DateTime>[];
  List<String> locations = <String>[];
  History history = History();
  bool restock = true;
  String upc = '';
  String iuid = '';

  Inventory();
  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryToJson(this);

  Inventory.withUPC(this.upc) {
    history.upc = upc;
  }
  bool get canPredict {
    return history.canPredict;
  }

  bool get isPredictedOut {
    return predictedAmount <= 0;
  }

  String get lastUpdatedString {
    return lastUpdate != null ? DateFormat.yMMMd().format(lastUpdate!) : 'Never';
  }

  String get minutesToReduceByOneString {
    final reductionInMinutes = Duration(minutes: usageSpeedMinutes.round());

    return canPredict
        ? 'Quantity is reducing by 1 every:\n ${reductionInMinutes.toHumanReadableString()}.'
        : 'Please enter another valid quantity\nat a later date to allow quantity predictions to be made.';
  }

  double get predictedAmount {
    // If we can't predict anything, return the existing amount
    if (!canPredict) return amount;
    double predictedQuantity = history.predict(DateTime.now().millisecondsSinceEpoch);
    return predictedQuantity > 0 ? predictedQuantity.toDouble() : 0;
  }

  DateTime get predictedOutDate {
    // Predicted out date is undefined. Code should be checking
    // canPredict before using this value.
    if (!canPredict) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(history.predictedOutageTimestamp);
  }

  String get predictedOutDateString {
    return canPredict
        ? DateFormat.yMd().add_jm().format(predictedOutDate)
        : 'No product history available to make predictions.';
  }

  Duration get predictedTimeUntilOut {
    if (!canPredict) {
      return const Duration(milliseconds: 0);
    }

    int millisecondsUntilOut =
        history.predictedOutageTimestamp - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: millisecondsUntilOut.abs());
  }

  String get predictedTimeUntilOutString {
    assert(canPredict);
    final alreadyGoneString =
        '${'Item was gone ${predictedTimeUntilOut.toHumanReadableString()}'} ago.';
    final timeUntilGoneString =
        '${'${'Item will be gone in ${predictedTimeUntilOut.toHumanReadableString()}'}\nat ${DateFormat.yMd().add_jm().format(predictedOutDate)}'}.';

    return isPredictedOut ? alreadyGoneString : timeUntilGoneString;
  }

  double get predictedUnits {
    return predictedAmount * unitCount;
  }

  double get preferredAmount {
    if (canPredict) {
      return unitCount == 1 ? predictedAmount : predictedUnits.roundTo(0);
    } else {
      return unitCount == 1 ? amount : units.roundTo(0);
    }
  }

  String get preferredAmountString {
    return unitCount == 1 ? preferredAmount.toStringAsFixed(2) : preferredAmount.toStringAsFixed(0);
  }

  Duration get timeSinceLastUpdate {
    assert(lastUpdate != null && lastUpdate != DateTime.fromMillisecondsSinceEpoch(0));
    return DateTime.now().difference(lastUpdate!);
  }

  String get timeSinceLastUpdateString {
    if (lastUpdate != null && lastUpdate != DateTime.fromMillisecondsSinceEpoch(0)) {
      return 'Amount updated ${timeSinceLastUpdate.toHumanReadableString()} ago.';
    } else {
      return 'Amount not updated recently.';
    }
  }

  double get units {
    return amount * unitCount;
  }

  set units(double value) {
    assert(unitCount != 0);
    amount = value / unitCount;
  }

  double get usageSpeedDays {
    return history.regressor.hasSlope
        ? (1 / history.regressor.slope.abs()) / 1000 / 60 / 60 / 24
        : 0;
  }

  double get usageSpeedMinutes {
    return history.regressor.hasSlope ? (1 / history.regressor.slope.abs()) / 1000 / 60 : 0;
  }
}

class OptDateTimeSerializer implements JsonConverter<DateTime?, int> {
  const OptDateTimeSerializer();

  @override
  DateTime? fromJson(int json) => json == 0 ? null : DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime? dateTime) => dateTime != null ? dateTime.millisecondsSinceEpoch : 0;
}
