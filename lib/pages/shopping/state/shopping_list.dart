import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';

final shoppingListProvider = StateNotifierProvider<ShoppingList, ShoppingListState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return ShoppingList(repo);
});

class ShoppingList extends StateNotifier<ShoppingListState> {
  final Repository repo;

  ShoppingList(this.repo)
      : super(ShoppingListState(
          shoppingItems: [],
          savedItems: [],
          cartItems: [],
        )) {
    refreshAll();
  }

  Future<void> add(ShoppingItem item) async {
    repo.shopping.put(item);
    await refreshAll();
  }

  Future<void> check(String itemId, bool checked) async {
    int itemIndex = state.shoppingItems.indexWhere((i) => i.uid == itemId);

    if (itemIndex != -1) {
      var updatedItem = state.shoppingItems[itemIndex].copyWith(checked: checked);
      state.shoppingItems[itemIndex] = updatedItem;
      repo.shopping.put(updatedItem);
      sortItems();
    }
  }

  void completeTrip() {
    final now = DateTime.now();

    for (final item in state.cartItems) {
      // Pull the latest version from the database if possible
      var inventory = repo.inv.get(item.inventory.upc) ?? item.inventory;

      // User might not have updated the amount in a while.
      // Update the amount to the predicted amount before we increment
      // it. Still not totally accurate, but should be better
      // than using a old likely inaccurate amount.
      inventory = inventory.updateAmountToPrediction();

      inventory = inventory.copyWith(
        updated: now,
        amount: inventory.amount + 1,
      );

      final newHistory = inventory.history.add(now.millisecondsSinceEpoch, inventory.amount, 2);

      repo.inv.put(inventory);
      repo.hist.put(newHistory);
    }

    // Delete all items from the cart in the database
    for (final item in state.cartItems) {
      repo.shopping.deleteById(item.uid);
    }

    state = state.copyWith(
      cartItems: [],
    );
  }

  List<ShoppingItem> outs() {
    int daysUntilOut = repo.prefs.getInt(PreferenceKey.restockDayCount) ?? 12;
    final predictedOutUpcList = repo.hist.predictedOuts(days: daysUntilOut);
    final predictedOuts = repo.inv.getAll(predictedOutUpcList.toList());
    final outs = repo.inv.outs();

    // Build a map of the outs
    Map<String, Inventory> combinedOuts = {for (final out in outs) out.upc: out};

    for (final out in predictedOuts) {
      if (!combinedOuts.containsKey(out.item.upc)) {
        combinedOuts[out.item.upc] = out;
      }
    }

    return combinedOuts.values.map((out) {
      return ShoppingItem(
        upc: out.upc,
        name: out.item.name,
        category: out.item.category,
      );
    }).toList();
  }

  Future<void> refreshAll() async {
    final allItems = repo.shopping.map();

    // Get the list of outs, and add them to the shopping list
    // List<ShoppingItem> outs = this.outs();
    // for (final out in outs) {
    //   // Only add the out if it's not already in the list
    //   if (!allItems.containsKey(out.uid)) {
    //     allItems[out.uid] = out;
    //   }
    // }

    final itemList = allItems.values.toList();

    state = state.copyWith(
      shoppingItems: sortList(itemList),
      savedItems: sortList(
        itemList,
      ),
      cartItems: sortList(itemList),
    );
  }

  Future<void> remove(String itemId) async {
    repo.shopping.deleteById(itemId);
    await refreshAll();
  }

  void sortItems() {
    state = state.copyWith(
        shoppingItems: sortList(state.shoppingItems),
        savedItems: sortList(state.savedItems),
        cartItems: sortList(state.cartItems));
  }

  List<ShoppingItem> sortList(List<ShoppingItem> items) {
    return items
      ..sort((a, b) {
        if (a.checked == b.checked) return a.name.compareTo(b.name);
        return a.checked ? 1 : -1;
      });
  }

  void updateItem(ShoppingItem item) {
    repo.shopping.put(item);
    final list = item.listName;

    if (list == ShoppingListName.shopping) {
      state = state.copyWith(
          shoppingItems: state.shoppingItems.map((i) => i.uid == item.uid ? item : i).toList());
    } else if (list == ShoppingListName.saved) {
      state = state.copyWith(
          savedItems: state.savedItems.map((i) => i.uid == item.uid ? item : i).toList());
    } else if (list == ShoppingListName.cart) {
      state = state.copyWith(
          cartItems: state.cartItems.map((i) => i.uid == item.uid ? item : i).toList());
    }
  }
}

class ShoppingListState {
  final List<ShoppingItem> shoppingItems;
  final List<ShoppingItem> savedItems;
  final List<ShoppingItem> cartItems;

  ShoppingListState({
    required this.shoppingItems,
    required this.savedItems,
    required this.cartItems,
  });

  ShoppingListState copyWith({
    List<ShoppingItem>? shoppingItems,
    List<ShoppingItem>? savedItems,
    List<ShoppingItem>? cartItems,
  }) {
    return ShoppingListState(
      shoppingItems: shoppingItems ?? this.shoppingItems,
      savedItems: savedItems ?? this.savedItems,
      cartItems: cartItems ?? this.cartItems,
    );
  }
}
