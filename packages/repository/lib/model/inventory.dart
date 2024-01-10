import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/duration.dart';
import 'package:repository/extension/list.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/regressor.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:stats/double.dart';

part 'inventory.g.dart';

@JsonSerializable(explicitToJson: true)
@Mergeable()
@immutable
class Inventory extends Model<Inventory> {
  @JsonKey(defaultValue: 0)
  final double amount;

  @JsonKey(defaultValue: 1)
  final int unitCount;

  @NullableDateTimeSerializer()
  final DateTime? lastUpdate;

  @JsonKey(defaultValue: [])
  final List<DateTime> expirationDates;

  @JsonKey(defaultValue: [])
  final List<String> locations;

  @JsonKey(includeFromJson: false, includeToJson: false, defaultValue: null)
  final History history; // generator:transient

  @JsonKey(defaultValue: true)
  final bool restock;

  @JsonKey(defaultValue: '', name: 'upc')
  final String _upc; // generator:unique, generator:property

  @JsonKey(defaultValue: '')
  final String uid;

  Inventory({
    this.amount = 0,
    this.unitCount = 1,
    this.lastUpdate,
    this.expirationDates = const <DateTime>[],
    this.locations = const <String>[],
    History? history,
    this.restock = true,
    String upc = '',
    this.uid = '',
  })  : _upc = upc,
        history = history?.copy() ?? History();

  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);

  bool get canPredict {
    return history.canPredict;
  }

  @override
  String get id => upc;

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

  @JsonKey(includeFromJson: false, includeToJson: false)
  double get units {
    return amount * unitCount;
  }

  String get upc => _upc;

  double get usageRateDays {
    return history.regressor.usageRateDays;
  }

  double get usageSpeedMinutes {
    return history.regressor.hasSlope ? (1 / history.regressor.slope.abs()) / 1000 / 60 : 0;
  }

  Inventory copyWith({
    double? amount,
    int? unitCount,
    DateTime? lastUpdate,
    List<DateTime>? expirationDates,
    List<String>? locations,
    History? history,
    bool? restock,
    String? upc,
    String? uid,
  }) {
    String newUpc = upc ?? _upc;

    return Inventory(
      amount: amount ?? this.amount,
      unitCount: unitCount ?? this.unitCount,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      expirationDates: expirationDates ?? this.expirationDates,
      locations: locations ?? this.locations,
      history: history?.copy(newUpc: newUpc) ?? this.history,
      restock: restock ?? this.restock,
      upc: newUpc,
      uid: uid ?? this.uid,
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
          uid == other.uid;

  @override
  Inventory merge(Inventory other) => _$mergeInventory(this, other);

  @override
  Map<String, dynamic> toJson() => _$InventoryToJson(this);

  Inventory withUnits(double value) {
    assert(unitCount != 0);
    double newAmount = value / unitCount;
    return copyWith(amount: newAmount);
  }

  Inventory _$mergeInventory(Inventory first, Inventory second) {
    final firstUpdate = first.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final secondUpdate = second.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final newerInventory = secondUpdate.isAfter(firstUpdate) ? second : first;
    return Inventory(
      amount: newerInventory.amount,
      unitCount: newerInventory.unitCount != 1 ? newerInventory.unitCount : first.unitCount,
      lastUpdate: newerInventory.lastUpdate ?? first.lastUpdate,
      expirationDates: {...newerInventory.expirationDates, ...first.expirationDates}.toList(),
      locations: {...newerInventory.locations, ...first.locations}.toList(),
      history: newerInventory.history,
      restock: newerInventory.restock,
      upc: newerInventory._upc.isNotEmpty ? newerInventory._upc : first._upc,
      uid: newerInventory.uid.isNotEmpty ? newerInventory.uid : first.uid,
    );
  }
}
