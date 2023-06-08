import 'package:intl/intl.dart';
import 'package:quiver/core.dart';
import 'package:repository/ml/ml_history.dart';
import 'package:stats/double.dart';

class Inventory {
  Inventory();
  double amount = 0;
  int unitCount = 1;

  Optional<DateTime> lastUpdate = const Optional.absent();
  List<DateTime> expirationDates = <DateTime>[];
  List<String> locations = <String>[];
  MLHistory history = MLHistory();
  bool restock = true;

  // Reference to Item
  String upc = '';
  String iuid = '';

  double get units {
    return amount * unitCount;
  }

  set units(double value) {
    assert(unitCount != 0);
    amount = value / unitCount;
  }

//   int get dbLastUpdate {
//     return lastUpdate.isPresent ? lastUpdate.value.millisecondsSinceEpoch : 0;
//   }

//   set dbLastUpdate(int value) {
//     lastUpdate = value != 0
//         ? Optional.of(DateTime.fromMillisecondsSinceEpoch(value))
//         : const Optional.absent();
//   }

//   List<String> get dbExpirationDates {
//     List<String> dates = [];
//     for (final exp in expirationDates) {
//       dates.add(exp.millisecondsSinceEpoch.toString());
//     }

//     return dates;
//   }

//   set dbExpirationDates(List<String> dates) {
//     expirationDates.clear();

//     for (final date in dates) {
//       int? timestamp = int.tryParse(date);

//       if (timestamp != null) {
//         expirationDates.add(DateTime.fromMillisecondsSinceEpoch(timestamp));
//       }
//     }
//   }

//   String get lastUpdatedString {
//     return lastUpdate.isPresent ? DateFormat.yMMMd().format(lastUpdate.value) : 'Never';
//   }

//   Duration get timeSinceLastUpdate {
//     assert(lastUpdate.isPresent);
//     return DateTime.now().difference(lastUpdate.value);
//   }

//   String get timeSinceLastUpdateString {
//     if (lastUpdate.isPresent) {
//       return 'Amount updated ${timeSinceLastUpdate.toHumanReadableString()} ago.';
//     } else {
//       return 'Amount not updated recently.';
//     }
//   }

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
    return lastUpdate.isPresent && history.canPredict;
  }

  bool get isPredictedOut {
    return predictedAmount <= 0;
  }

//   String get minutesToReduceByOneString {
//     final reductionInMinutes = Duration(minutes: usageSpeedMinutes.round());

//     return canPredictAmount
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

  // String get predictedTimeUntilOutString {
  //   assert(canPredict);
  //   final alreadyGoneString =
  //       '${'Item was gone ' + predictedTimeUntilOut.toHumanReadableString()} ago.';
  //   final timeUntilGoneString =
  //       '${'${'Item will be gone in ' + predictedTimeUntilOut.toHumanReadableString()}\nat ${DateFormat.yMd().add_jm().format(predictedOutDate)}'}.';

  //   return isPredictedOut ? alreadyGoneString : timeUntilGoneString;
  // }

  double get predictedUnits {
    return predictedAmount * unitCount;
  }

  double get preferredAmount {
    return unitCount == 1 ? amount : units;
  }

  String get preferredAmountString {
    return preferredAmount.roundTo(2).toString();
  }

  String get preferredPredictedUnitString {
    return canPredict
        ? predictedUnits.toStringAsFixed(2).toString()
        : units.toStringAsFixed(2).toString();
  }
}
