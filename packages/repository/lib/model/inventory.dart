import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/regressor.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/model_provider.dart';
import 'package:repository/util/hash.dart';
import 'package:util/extension/date_time.dart';
import 'package:util/extension/double.dart';
import 'package:util/extension/duration.dart';
import 'package:util/extension/list.dart';
import 'package:uuid/uuid.dart';

part 'inventory.g.dart';
part 'inventory.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class Inventory extends Model<Inventory> {
  final double amount;
  final int unitCount;
  final List<String> locations;
  final List<DateTime> expirationDates;
  final bool restock;
  final String uid;
  final String upc; // generator:unique
  final String householdId;

  Inventory({
    this.amount = 0,
    this.unitCount = 1,
    this.expirationDates = const <DateTime>[],
    this.locations = const <String>[],
    this.restock = true,
    this.upc = '',
    String? uid,
    this.householdId = '',
    super.created,
    super.updated,
  }) : uid = uid != null && uid.isNotEmpty
            ? uid
            : (upc.isNotEmpty ? hashBarcode(upc) : const Uuid().v4());

  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);

  bool get canPredict {
    return history.canPredict;
  }

  History get history => ModelProvider<History>().get(upc, History(upc: upc));

  bool get isPredictedOut {
    return predictedAmount <= 0;
  }

  Item get item => ModelProvider<Item>().get(upc, Item(upc: upc));

  String get lastUpdatedString {
    return DateFormat.yMMMd().format(updated);
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
    double predictedQuantity = history.predict(DateTime.now().millisecondsSinceEpoch.toDouble());
    return predictedQuantity > 0 ? predictedQuantity.toDouble() : 0;
  }

  DateTime get predictedOutDate {
    // Predicted out date is undefined. Code should be checking
    // canPredict before using this value.
    if (!canPredict) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(history.predictedOutageTimestamp.round());
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

    double millisecondsUntilOut =
        history.predictedOutageTimestamp - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: millisecondsUntilOut.round().abs());
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
    // With no unit count specified, we show the amount in a percentage.
    // However, if the amount is 0, we show 0% instead of 0.0%
    // Also, if the amount is greater than 1, we just show
    // the units instead of something like 350% which doesn't make
    // much sense.
    if (unitCount == 1 && (preferredAmount.roundTo(1) > 0)) {
      return preferredAmount.toStringAsFixed(2);
    }

    // There is a unit count specified, so we show the
    // amount in total units
    else {
      return preferredAmount.toStringAsFixed(0);
    }
  }

  Duration get timeSinceLastUpdate {
    assert(updated != DateTime.fromMillisecondsSinceEpoch(0));
    return DateTime.now().difference(updated);
  }

  String get timeSinceLastUpdateString {
    if (updated != DateTime.fromMillisecondsSinceEpoch(0)) {
      return 'Amount updated ${timeSinceLastUpdate.toHumanReadableString()} ago.';
    } else {
      return 'Amount not updated recently.';
    }
  }

  @override
  String get uniqueKey => upc;

  @JsonKey(includeFromJson: false, includeToJson: false)
  double get units {
    return amount * unitCount;
  }

  double get usageRateDays {
    return history.regressor.usageRateDays;
  }

  double get usageSpeedMinutes {
    return history.regressor.hasSlope ? (1 / history.regressor.slope.abs()) / 1000 / 60 : 0;
  }

  @override
  Inventory copyWith({
    double? amount,
    int? unitCount,
    List<DateTime>? expirationDates,
    List<String>? locations,
    bool? restock,
    String? upc,
    String? uid,
    String? householdId,
    DateTime? created,
    DateTime? updated,
  }) {
    return Inventory(
      amount: amount ?? this.amount,
      unitCount: unitCount ?? this.unitCount,
      expirationDates: expirationDates ?? this.expirationDates,
      locations: locations ?? this.locations,
      restock: restock ?? this.restock,
      upc: upc ?? this.upc,
      uid: uid != null && uid.isNotEmpty
          ? uid
          : (upc != null && upc.isNotEmpty ? hashBarcode(upc) : this.uid),
      householdId: householdId ?? this.householdId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Inventory other) =>
      identical(this, other) ||
      amount == other.amount &&
          unitCount == other.unitCount &&
          expirationDates.equals(other.expirationDates) &&
          locations.equals(other.locations) &&
          restock == other.restock &&
          upc == other.upc &&
          uid == other.uid &&
          householdId == other.householdId;

  @override
  Inventory merge(Inventory other) => _$mergeInventory(this, other);

  @override
  Map<String, dynamic> toJson() => _$InventoryToJson(this);

  /// Update the amount to the predicted amount if the last update was more than a day ago.
  Inventory updateAmountToPrediction() {
    final now = DateTime.now();

    if (canPredict && history.lastTimestamp != null) {
      final lastTimestamp = history.lastTimestamp;
      final timeSinceLastUpdate = now.difference(lastTimestamp!);

      // The last history update was more than a day ago, use predicted
      if (timeSinceLastUpdate.inDays > 1) {
        return copyWith(amount: predictedAmount);
      }
    }

    // Note that if the last update was less than a day ago, we'll
    // just use the last amount by default, because this is probably accurate.
    return this;
  }

  Inventory updateAmountToPredictionAtTimestamp(int timestamp) {
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp));

    if (canPredict && timeSinceLastUpdate.inDays > 1) {
      final predictedQuantity = history.predict(timestamp.toDouble());
      return copyWith(amount: predictedQuantity);
    }

    return this;
  }

  Inventory withUnits(double value) {
    assert(unitCount != 0);
    double newAmount = value / unitCount;
    return copyWith(amount: newAmount);
  }
}
