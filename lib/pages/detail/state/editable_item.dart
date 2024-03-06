import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/identifier_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_provider.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:repository/util/hash.dart';
import 'package:stats/double.dart';
import 'package:uuid/uuid.dart';

final editableItemProvider = StateNotifierProvider<EditableItem, EditableItemState>((ref) {
  return EditableItem();
});

class EditableItem extends StateNotifier<EditableItemState> {
  EditableItem() : super(EditableItemState.empty());

  List<MapEntry<int, double>> get allHistoryEntries {
    final entries = <MapEntry<int, double>>[];
    for (final eachSeries in state.history.series) {
      final allEntries =
          eachSeries.observations.map((o) => MapEntry(o.timestamp.toInt(), o.amount)).toList();
      allEntries.sort((a, b) => a.key.compareTo(b.key));
      entries.addAll(allEntries);
    }
    return entries;
  }

  double get amount => state.inventory.amount;

  set amount(double amount) {
    var inv = state.inventory;
    inv = inv.copyWith(amount: amount);

    // Note that we do not modify history here. We will call
    // history.add in the save method if the amount has changed.

    state.changedFields.add('amount');
    state = EditableItemState(state.item, inv, state.history, state.changedFields);
  }

  bool get consumable => state.item.consumable;

  set consumable(bool consumable) {
    final item = state.item.copyWith(consumable: consumable);

    state.changedFields.add('consumable');
    state = EditableItemState(item, state.inventory, state.history, state.changedFields);
  }

  List<MapEntry<int, double>> get currentHistorySeries {
    if (state.history.series.isEmpty) {
      return [];
    }

    final series = state.history.series.last;
    final entries =
        series.observations.map((o) => MapEntry(o.timestamp.toInt(), o.amount)).toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  Map<String, String> get identifiers => state.identifiers;
  String get imageUrl => state.item.imageUrl;

  set imageUrl(String imageUrl) {
    final item = state.item.copyWith(imageUrl: imageUrl.trim());

    state.changedFields.add('imageUrl');
    state = EditableItemState(item, state.inventory, state.history, state.changedFields);
  }

  List<String> get locations => state.inventory.locations;
  String get name => state.item.name;

  set name(String name) {
    final item = state.item.copyWith(name: name.trim());

    state = EditableItemState(item, state.inventory, state.history, state.changedFields);
  }

  String get predictedAmount => state.inventory.predictedAmount.toStringNoZero(2);

  double get totalUnitCount => state.inventory.units;
  String get type => state.item.type;

  set type(String type) {
    final item = state.item.copyWith(type: type.trim());

    state.changedFields.add('type');
    state = EditableItemState(item, state.inventory, state.history, state.changedFields);
  }

  String get uid => state.item.uid;

  int get unitCount => state.inventory.unitCount;

  set unitCount(int value) {
    final inv = state.inventory.copyWith(unitCount: value);
    final item = state.item.copyWith(unitCount: value);

    state = EditableItemState(item, inv, state.history, state.changedFields);
  }

  List<String> get unusedIdentifierTypes {
    final usedTypes = state.identifiers.keys.toSet();
    usedTypes.add(IdentifierType.upc);

    final allTypes = IdentifierType.validIdentifierTypes;
    return allTypes.difference(usedTypes).toList();
  }

  String get upc => state.item.upc;

  set upc(String upc) {
    upc = upc.trim();

    final item = state.item.copyWith(upc: upc);
    final history = state.history.copyWith(upc: upc);
    final inv = state.inventory.copyWith(upc: upc);

    state = EditableItemState(item, inv, history, state.changedFields);
  }

  String get variety => state.item.variety;

  set variety(String variety) {
    final item = state.item.copyWith(variety: variety.trim());
    state = EditableItemState(item, state.inventory, state.history, state.changedFields);
  }

  void addIdentifier(String key) {
    if (key.isEmpty || state.identifiers.containsKey(key) || !IdentifierType.isValid(key)) {
      Log.w('Attempted to add invalid identifier type: $key for upc: ${state.item.upc}.');
      return;
    }

    state.identifiers[key] = '';
    state = EditableItemState(
        state.item, state.inventory, state.history, state.changedFields, state.identifiers);
  }

  void addLocation(String location) {
    location = location.trim();
    final inv = state.inventory;

    // Don't add the location if it already exists
    if (!inv.locations.contains(location)) {
      inv.locations.add(location);
      state = EditableItemState(state.item, inv, state.history, state.changedFields);
    }
  }

  void cleanUpHistory(Repository repo) {
    var inv = state.inventory;
    var history = state.history;

    final cleanHistory = history.clean(warn: true);
    state.history = cleanHistory;

    repo.inv.put(inv);
    repo.hist.put(cleanHistory);
    HistoryProvider().updateHistory(cleanHistory, allowDataLoss: true);

    state = EditableItemState(state.item, inv, state.history, state.changedFields);
  }

  void deleteHistorySeries(int index) {
    var history = state.history;
    history = history.delete(index);

    state.changedFields.add('history');
    state = EditableItemState(state.item, state.inventory, history, state.changedFields);
  }

  void init(Item item, Inventory inv, [Map<String, String> identifiers = const {}]) {
    assert(item.upc == inv.upc);
    assert(item.upc == inv.history.upc);

    // If the item is missing a uid, generate one
    if (item.uid.isEmpty) {
      var itemUid = item.upc.isNotEmpty ? hashBarcode(item.upc) : const Uuid().v4();
      item = item.copyWith(uid: itemUid);
    }

    // The inventory should point to the same uid as the item
    if (inv.uid.isEmpty || inv.uid != item.uid) {
      inv = inv.copyWith(uid: item.uid);
    }

    state = EditableItemState(item, inv, inv.history, state.changedFields, identifiers);
  }

  void removeLocation(String location) {
    location = location.trim();
    final inv = state.inventory;

    if (inv.locations.contains(location)) {
      inv.locations.remove(location);
      state = EditableItemState(state.item, inv, state.history, state.changedFields);
    }
  }

  void save(Repository repo) {
    assert(state.item.upc == state.inventory.upc);
    assert(state.item.upc == state.history.upc);

    final saveTimestamp = DateTime.now();

    // Make sure we update the last updated timestamp
    state.item = state.item.copyWith(updated: saveTimestamp);
    state.inventory = state.inventory.copyWith(updated: saveTimestamp);

    repo.items.put(state.item);
    repo.inv.put(state.inventory);

    // If the amount changed, add a new history entry
    if (state.changedFields.contains('amount') ||
        state.history.series.isEmpty ||
        state.history.series.last.observations.isEmpty) {
      final newHistory =
          state.history.add(saveTimestamp.millisecondsSinceEpoch, state.inventory.amount, 2);
      state.history = newHistory;

      repo.hist.put(newHistory);
      HistoryProvider().updateHistory(newHistory);
    }

    // If we deleted history, we should still update it
    else if (state.changedFields.contains('history')) {
      repo.hist.put(state.history);
      HistoryProvider().updateHistory(state.history, allowDataLoss: true);
    }

    // Save each location
    for (final location in state.inventory.locations) {
      repo.location.store(location, state.item.upc);
    }

    // Save all identifiers
    for (final entry in state.identifiers.entries) {
      // Ensure all data is present
      if (entry.key.isEmpty || entry.value.isEmpty || state.item.uid.isEmpty) {
        Log.w(
            'Invalid identifier: "${entry.key}=${entry.value}" for upc: ${state.item.upc} and uid ${state.item.uid}. Skipping.');
        continue;
      }

      // Ensure the identifier type is valid
      if (!IdentifierType.isValid(entry.key)) {
        Log.w('Invalid identifier type: ${entry.key} for upc: ${state.item.upc}. Skipping.');
        continue;
      }

      final identifier = Identifier(
        type: entry.key,
        value: entry.value,
        uid: state.item.uid,
      );

      repo.identifiers.put(identifier);
    }
  }

  void updateIdentifier(String key, String value) {
    state.identifiers[key] = value;
  }
}

class EditableItemState {
  Item item = Item();
  Inventory inventory = Inventory();
  History history = History();
  Set<String> changedFields = {};
  Map<String, String> identifiers = {};

  EditableItemState(this.item, this.inventory, this.history, this.changedFields,
      [this.identifiers = const {}]);
  EditableItemState.empty();
}
