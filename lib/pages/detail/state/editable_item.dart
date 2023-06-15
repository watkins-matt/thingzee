import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quiver/core.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:stats/double.dart';

final editableItemProvider = StateNotifierProvider<EditableItem, EditableItemState>((ref) {
  return EditableItem();
});

class EditableItemState {
  Item item = Item();
  Inventory inventory = Inventory();
  Set<String> changedFields = {};

  EditableItemState.empty();
  EditableItemState(this.item, this.inventory, this.changedFields);
}

class EditableItem extends StateNotifier<EditableItemState> {
  EditableItem() : super(EditableItemState.empty());

  void copyFrom(Item item, Inventory inv) {
    copyFromItem(item);
    copyFromInventory(inv);
  }

  void copyFromItem(Item item) {
    Item copiedItem = Item();
    copiedItem.name = item.name;
    copiedItem.variety = item.variety;
    copiedItem.upc = item.upc;
    copiedItem.imageUrl = item.imageUrl;
    copiedItem.category = item.category;
    copiedItem.unitCount = item.unitCount;

    // Make sure the upc is copied to the inventory
    if (state.inventory.upc != copiedItem.upc) {
      state.inventory.upc = copiedItem.upc;
    }

    if (state.inventory.history.upc != copiedItem.upc) {
      state.inventory.history.upc = copiedItem.upc;
    }

    state = EditableItemState(copiedItem, state.inventory, state.changedFields);
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

  String get name => state.item.name;
  set name(String name) {
    final item = state.item;
    item.name = name;

    state = EditableItemState(item, state.inventory, state.changedFields);
  }

  String get variety => state.item.variety;
  set variety(String variety) {
    final item = state.item;
    item.variety = variety;

    state = EditableItemState(item, state.inventory, state.changedFields);
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

  String get predictedAmount {
    if (state.inventory.history.canPredict) {
      final amount = state.inventory.history.predict(DateTime.now().millisecondsSinceEpoch);
      return amount.toStringNoZero(2);
    }

    return amount.toStringNoZero(2);
  }

  double get amount => state.inventory.amount;
  set amount(double amount) {
    final inv = state.inventory;
    inv.amount = amount;

    state.changedFields.add('amount');
    state = EditableItemState(state.item, inv, state.changedFields);
  }

  int get unitCount => state.inventory.unitCount;
  set unitCount(int value) {
    final inv = state.inventory;
    inv.unitCount = value;

    final item = state.item;
    item.unitCount = value;

    state = EditableItemState(item, inv, state.changedFields);
  }

  double get totalUnitCount => state.inventory.units;

  void save(Repository repo) {
    repo.items.put(state.item);

    // We want to avoid saving useless inventory information if the amount is 0.
    // We will always save the inventory if it is greater than 0, or if
    // the inventory already exists in the database (because it was greater
    // than 0 at some point)
    if (state.inventory.amount > 0 || repo.inv.get(state.inventory.upc).isNotEmpty) {
      assert(state.inventory.upc == state.item.upc);

      if (state.changedFields.contains('amount')) {
        state.inventory.history
            .add(DateTime.now().millisecondsSinceEpoch, state.inventory.amount, 2);
      }

      // Make sure we update the last updated time
      state.inventory.lastUpdate = Optional.of(DateTime.now());

      repo.inv.put(state.inventory);
    }
  }
}
