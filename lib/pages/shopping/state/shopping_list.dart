import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/app.dart';

final shoppingListProvider = StateNotifierProvider<ShoppingList, ShoppingListState>((ref) {
  return ShoppingList(App.repo);
});

class ShoppingList extends StateNotifier<ShoppingListState> {
  final Repository repo;
  JoinedItemDatabase db;

  ShoppingList(this.repo)
      : db = JoinedItemDatabase(repo.items, repo.inv),
        super(ShoppingListState([], {})) {
    _populateList();
  }

  void check(int index, bool value) {
    final items = state.items;
    assert(index < items.length);

    var checked = state.checked;
    final item = items[index].item;

    if (value) {
      checked.add(item.upc);
    } else {
      checked.remove(item.upc);
    }

    sortItems(items);
    state = state.copyWith(items: items, checked: checked);
  }

  bool isChecked(int index) {
    final items = state.items;
    assert(index < items.length);

    final item = items[index].item;
    return state.checked.contains(item.upc);
  }

  void removeAt(int index) {
    var items = state.items;
    assert(index < items.length);
    final item = items[index].item;

    // TODO: Turn off restock for this item here if removed from list

    // Remove the item from the list
    items.removeAt(index);

    // Remove the check if present
    var checked = state.checked;
    checked.remove(item.upc);

    state = state.copyWith(
      items: items,
      checked: checked,
    );
  }

  void sortItems(List<JoinedItem> items) {
    items.sort((a, b) {
      if (state.checked.contains(a.item.upc) == state.checked.contains(b.item.upc)) {
        return a.item.name.compareTo(b.item.name);
      }
      if (state.checked.contains(a.item.upc)) {
        return 1;
      } else {
        return -1;
      }
    });
  }

  void _populateList() {
    List<JoinedItem> outs = db.outs();
    List<JoinedItem> predictedOuts = db.predictedOuts(repo.hist);

    outs.addAll(predictedOuts);
    sortItems(outs);

    state = state.copyWith(
      items: outs,
    );
  }
}

class ShoppingListState {
  final List<JoinedItem> items;
  final Set<String> checked;

  ShoppingListState(this.items, this.checked);

  ShoppingListState copyWith({
    List<JoinedItem>? items,
    Set<String>? checked,
  }) {
    return ShoppingListState(
      items ?? this.items,
      checked ?? this.checked,
    );
  }
}
