import 'package:intl/intl.dart';
import 'package:quiver/core.dart';
import 'package:repository/extension/duration.dart';
import 'package:repository/ml/history.dart';
import 'package:stats/double.dart';

class Inventory {
  double amount = 0;
  int unitCount = 1;
  Optional<DateTime> lastUpdate = const Optional.absent();
  List<DateTime> expirationDates = <DateTime>[];
  List<String> locations = <String>[];
  History history = History();
  bool restock = true;
  String upc = '';
  String iuid = '';
  Inventory();
  Inventory.withUPC(this.upc) {
    history.upc = upc;
  }

  // double get usageSpeedMinutes {
  //   return history.best.
  // }

//   double get usageSpeedMinutes {
//     return history.currentSeriesRegression == 0
//         ? 0
//         : (1 / history.currentSeriesRegression.abs()) / 1000 / 60;
//   }

//   double get usageSpeedDays {
//     return history.currentSeriesRegression == 0
//         ? 0
//         : (1 / history.currentSeriesRegression.abs()) / 1000 / 60 / 60 / 24;
//   }

  bool get canPredict {
    return history.canPredict;
  }

  bool get isPredictedOut {
    return predictedAmount <= 0;
  }

  String get lastUpdatedString {
    return lastUpdate.isPresent ? DateFormat.yMMMd().format(lastUpdate.value) : 'Never';
  }

  //   String get minutesToReduceByOneString {
//     final reductionInMinutes = Duration(minutes: usageSpeedMinutes.round());

//     return canPredict
//         ? 'Quantity is reducing by 1 every:\n ${reductionInMinutes.toHumanReadableString()}.'
//         : 'Please enter another valid quantity\nat a later date to allow quantity predictions to be made.';
//   }

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
    return unitCount == 1 ? amount : units;
  }

  String get preferredAmountString {
    return preferredAmount.roundTo(2).toString();
  }

  double get preferredPredictedAmount {
    return canPredict ? predictedUnits : units;
  }

  String get preferredPredictedUnitString {
    return canPredict
        ? predictedUnits.toStringAsFixed(2).toString()
        : units.toStringAsFixed(2).toString();
  }

  Duration get timeSinceLastUpdate {
    assert(lastUpdate.isPresent);
    return DateTime.now().difference(lastUpdate.value);
  }

  String get timeSinceLastUpdateString {
    if (lastUpdate.isPresent) {
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
}
