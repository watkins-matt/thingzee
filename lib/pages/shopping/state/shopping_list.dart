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

  void _populateList() {
    List<JoinedItem> outs = db.outs();
    List<JoinedItem> predictedOuts = db.predictedOuts(repo.hist);

    outs.addAll(predictedOuts);
    outs.sort();

    state = state.copyWith(
      items: outs,
    );
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

    state = state.copyWith(
      checked: checked,
    );
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
