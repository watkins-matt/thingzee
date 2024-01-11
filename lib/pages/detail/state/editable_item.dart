import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:stats/double.dart';

final editableItemProvider = StateNotifierProvider<EditableItem, EditableItemState>((ref) {
  return EditableItem();
});

class EditableItem extends StateNotifier<EditableItemState> {
  EditableItem() : super(EditableItemState.empty());

  List<MapEntry<int, double>> get allHistoryEntries {
    final entries = <MapEntry<int, double>>[];
    for (final eachSeries in state.inventory.history.series) {
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

    state.changedFields.add('amount');
    state = EditableItemState(state.item, inv, state.changedFields);
  }

  bool get consumable => state.item.consumable;

  set consumable(bool consumable) {
    final item = state.item.copyWith(consumable: consumable);

    state.changedFields.add('consumable');
    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  List<MapEntry<int, double>> get currentHistorySeries {
    if (state.inventory.history.series.isEmpty) {
      return [];
    }

    final series = state.inventory.history.series.last;
    final entries =
        series.observations.map((o) => MapEntry(o.timestamp.toInt(), o.amount)).toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  String get imageUrl => state.item.imageUrl;
  set imageUrl(String imageUrl) {
    final item = state.item.copyWith(imageUrl: imageUrl.trim());

    state.changedFields.add('imageUrl');
    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  List<String> get locations => state.inventory.locations;

  String get name => state.item.name;
  set name(String name) {
    final item = state.item.copyWith(name: name.trim());

    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  String get predictedAmount => state.inventory.predictedAmount.toStringNoZero(2);
  double get totalUnitCount => state.inventory.units;

  String get type => state.item.type;
  set type(String type) {
    final item = state.item.copyWith(type: type.trim());

    state.changedFields.add('type');
    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  int get unitCount => state.inventory.unitCount;
  set unitCount(int value) {
    final inv = state.inventory.copyWith(unitCount: value);
    final item = state.item.copyWith(unitCount: value);

    state = EditableItemState(item, inv, state.changedFields);
  }

  String get upc => state.item.upc;
  set upc(String upc) {
    upc = upc.trim();

    final item = state.item.copyWith(upc: upc);
    final history = state.inventory.history.copyWith(upc: upc);
    final inv = state.inventory.copyWith(upc: upc, history: history);

    state = EditableItemState(item, inv, state.changedFields);
  }

  String get variety => state.item.variety;
  set variety(String variety) {
    final item = state.item.copyWith(variety: variety.trim());

    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  void addLocation(String location) {
    location = location.trim();
    final inv = state.inventory;

    // Don't add the location if it already exists
    if (!inv.locations.contains(location)) {
      inv.locations.add(location);
      state = EditableItemState(state.item, inv, state.changedFields);
    }
  }

  void cleanUpHistory(Repository repo) {
    var inv = state.inventory;
    final cleanHistory = inv.history.clean(warn: true);
    inv = inv.copyWith(history: cleanHistory);

    // Save the inventory. Note that we use a joined db
    // here so saving the inventory also saves the history
    repo.inv.put(inv);

    state = EditableItemState(state.item, inv, state.changedFields);
  }

  void copyFrom(Item item, Inventory inv) {
    copyFromItem(item);
    copyFromInventory(inv);
  }

  void copyFromInventory(Inventory inv) {
    // Update the item's UPC
    Item updatedItem = state.item.copyWith(upc: inv.upc);

    // Create a new Inventory instance with updated History
    Inventory updatedInv = inv.copyWith(
      history: inv.history.copyWith(upc: inv.upc),
    );

    // Update the state with the new item and inventory
    state = EditableItemState(updatedItem, updatedInv, state.changedFields);
  }

  void copyFromItem(Item item) {
    // Create a new Item instance using copyWith
    Item updatedItem = item.copyWith();

    // Update the Inventory's UPC and History if necessary
    Inventory updatedInventory = state.inventory;

    if (state.inventory.upc != updatedItem.upc) {
      updatedInventory = updatedInventory.copyWith(upc: updatedItem.upc);
    }

    if (state.inventory.history.upc != updatedItem.upc) {
      updatedInventory = updatedInventory.copyWith(
        history: updatedInventory.history.copyWith(upc: updatedItem.upc),
      );
    }

    // Update the state with the new item and inventory
    state = EditableItemState(updatedItem, updatedInventory, state.changedFields);
  }

  void deleteHistorySeries(int index) {
    final inv = state.inventory;
    inv.history.delete(index);

    state = EditableItemState(state.item, inv, state.changedFields);
  }

  void removeLocation(String location) {
    location = location.trim();
    final inv = state.inventory;

    if (inv.locations.contains(location)) {
      inv.locations.remove(location);
      state = EditableItemState(state.item, inv, state.changedFields);
    }
  }

  void save(Repository repo) {
    final saveTimestamp = DateTime.now();
    state.item = state.item.copyWith(updated: saveTimestamp);

    repo.items.put(state.item);

    // If the amount changed, add a new history entry
    if (state.changedFields.contains('amount') ||
        state.inventory.history.series.isEmpty ||
        state.inventory.history.series.last.observations.isEmpty) {
      final newHistory = state.inventory.history
          .add(saveTimestamp.millisecondsSinceEpoch, state.inventory.amount, 2);
      state.inventory = state.inventory.copyWith(history: newHistory);
    }

    // Make sure we update the last updated timestamp
    state.inventory = state.inventory.copyWith(updated: saveTimestamp);

    assert(state.inventory.upc == state.item.upc);
    assert(state.inventory.history.upc == state.item.upc);
    repo.inv.put(state.inventory);

    // Save each location
    for (final location in state.inventory.locations) {
      repo.location.store(location, state.item.upc);
    }
  }
}

class EditableItemState {
  Item item = Item();
  Inventory inventory = Inventory();
  Set<String> changedFields = {};

  EditableItemState(this.item, this.inventory, this.changedFields);
  EditableItemState.empty();
}
