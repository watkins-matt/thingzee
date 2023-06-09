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
    final inv = state.inventory;
    inv.amount = amount;

    state.changedFields.add('amount');
    state = EditableItemState(state.item, inv, state.changedFields);
  }

  bool get consumable => state.item.consumable;

  set consumable(bool consumable) {
    final item = state.item;
    item.consumable = consumable;

    state.changedFields.add('consumable');
    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  String get name => state.item.name;

  set name(String name) {
    final item = state.item;
    item.name = name;

    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  String get predictedAmount => state.inventory.predictedAmount.toStringNoZero(2);

  double get totalUnitCount => state.inventory.units;
  int get unitCount => state.inventory.unitCount;

  set unitCount(int value) {
    final inv = state.inventory;
    inv.unitCount = value;

    final item = state.item;
    item.unitCount = value;

    state = EditableItemState(item, inv, state.changedFields);
  }

  String get upc => state.item.upc;

  set upc(String upc) {
    final item = state.item;
    item.upc = upc;

    final inv = state.inventory;
    inv.upc = upc;

    final history = state.inventory.history;
    history.upc = upc;

    state = EditableItemState(item, inv, state.changedFields);
  }

  String get variety => state.item.variety;
  set variety(String variety) {
    final item = state.item;
    item.variety = variety;

    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  void cleanUpHistory(Repository repo) {
    final inv = state.inventory;
    inv.history = inv.history.clean();
    repo.hist.put(inv.history);

    state = EditableItemState(state.item, inv, state.changedFields);
  }

  void copyFrom(Item item, Inventory inv) {
    copyFromItem(item);
    copyFromInventory(inv);
  }

  void copyFromInventory(Inventory inv) {
    Inventory copiedInv = Inventory();
    copiedInv.amount = inv.amount;
    copiedInv.upc = inv.upc;
    copiedInv.unitCount = inv.unitCount;
    copiedInv.history = inv.history;
    copiedInv.lastUpdate = inv.lastUpdate;

    // Make sure the upc is copied to the item
    if (state.item.upc != copiedInv.upc) {
      state.item.upc = copiedInv.upc;
    }

    if (state.inventory.history.upc != copiedInv.upc) {
      state.inventory.history.upc = copiedInv.upc;
    }

    state = EditableItemState(state.item, copiedInv, state.changedFields);
  }

  void copyFromItem(Item item) {
    Item copiedItem = Item();
    copiedItem.name = item.name;
    copiedItem.variety = item.variety;
    copiedItem.upc = item.upc;
    copiedItem.imageUrl = item.imageUrl;
    copiedItem.category = item.category;
    copiedItem.unitCount = item.unitCount;
    copiedItem.consumable = item.consumable;

    // Make sure the upc is copied to the inventory
    if (state.inventory.upc != copiedItem.upc) {
      state.inventory.upc = copiedItem.upc;
    }

    if (state.inventory.history.upc != copiedItem.upc) {
      state.inventory.history.upc = copiedItem.upc;
    }

    state = EditableItemState(copiedItem, state.inventory, state.changedFields);
  }

  void save(Repository repo) {
    final saveTimestamp = DateTime.now();
    state.item.lastUpdate = saveTimestamp;
    repo.items.put(state.item);

    // If the amount changed, add a new history entry
    if (state.changedFields.contains('amount')) {
      state.inventory.history.add(DateTime.now().millisecondsSinceEpoch, state.inventory.amount, 2);
    }

    // Make sure we update the last updated time
    state.inventory.lastUpdate = saveTimestamp;

    // Save the inventory
    assert(state.inventory.upc == state.item.upc);
    repo.inv.put(state.inventory);
  }
}

class EditableItemState {
  Item item = Item();
  Inventory inventory = Inventory();
  Set<String> changedFields = {};

  EditableItemState(this.item, this.inventory, this.changedFields);
  EditableItemState.empty();
}
