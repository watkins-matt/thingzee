import 'package:quiver/core.dart';
import 'package:stats/double.dart';

import 'history.dart';

class Inventory {
  Inventory();
  double amount = 0;
  int unitCount = 1;

  Optional<DateTime> lastUpdate = const Optional.absent();
  List<DateTime> expirationDates = <DateTime>[];
  List<String> locations = <String>[];
  History history = History();
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

  // set dbHistory(String value) {
  //   Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
  //   history = History.fromJson(json).trim();
  // }

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

//   @override
//   int compareTo(Product other) {
//     return name.compareTo(other.name);
//   }

  bool get canPredictAmount {
    return lastUpdate.isPresent && history.hasIntercept;
  }

//   bool get isPredictedOut {
//     return predictedAmount <= 0;
//   }

//   String get minutesToReduceByOneString {
//     final reductionInMinutes = Duration(minutes: usageSpeedMinutes.round());

//     return canPredictAmount
//         ? 'Quantity is reducing by 1 every:\n ${reductionInMinutes.toHumanReadableString()}.'
//         : 'Please enter another valid quantity\nat a later date to allow quantity predictions to be made.';
//   }

  double get predictedAmount {
    // If we can't predict anything, return the existing amount
    if (!canPredictAmount) return amount;
    double predictedQuantity = history.predict(DateTime.now().millisecondsSinceEpoch.toDouble());
    return predictedQuantity > 0 ? predictedQuantity.toDouble() : 0;
  }

//   DateTime get predictedOutDate {
//     assert(canPredictAmount);
//     // if (history.xIntercept.isNaN) {
//     //   var val = history.xIntercept;
//     //   val += 1;
//     // }

//     return DateTime.fromMillisecondsSinceEpoch(history.xIntercept.round());
//   }

//   String get predictedOutDateString {
//     return canPredictAmount
//         ? DateFormat.yMd().add_jm().format(predictedOutDate)
//         : 'No product history available to make predictions.';
//   }

//   Duration get predictedTimeUntilOut {
//     if (!canPredictAmount) {
//       return const Duration(milliseconds: 0);
//     }

//     double millisecondsUntilOut = history.xIntercept - DateTime.now().millisecondsSinceEpoch;
//     return Duration(milliseconds: millisecondsUntilOut.round().abs());
//   }

//   String get predictedTimeUntilOutString {
//     assert(canPredictAmount);
//     final alreadyGoneString =
//         '${'Item was gone ' + predictedTimeUntilOut.toHumanReadableString()} ago.';
//     final timeUntilGoneString =
//         '${'${'Item will be gone in ' + predictedTimeUntilOut.toHumanReadableString()}\nat ${DateFormat.yMd().add_jm().format(predictedOutDate)}'}.';

//     return isPredictedOut ? alreadyGoneString : timeUntilGoneString;
//   }

//   double get predictedUnits {
//     return predictedAmount * unitCount;
//   }

  double get preferredAmount {
    return unitCount == 1 ? amount : units;
  }

  String get preferredAmountString {
    return preferredAmount.roundTo(2).toString();
  }

  // String get preferredPredictedUnitString {
  //   return canPredictAmount
  //       ? predictedUnits.toStringAsFixed(2).toString()
  //       : units.toStringAsFixed(2).toString();
  // }
}
