import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';
import 'package:util/extension/list.dart';

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

  Map<String, List<ShoppingItem>> get shoppingItemsByList {
    final allItems = repo.shopping.all();
    var itemsMap = <String, List<ShoppingItem>>{};

    for (final item in allItems) {
      final list = item.listName;

      if (ShoppingListName.validIdentifierTypes.contains(list)) {
        itemsMap.putIfAbsent(list, () => []).add(item);
      }
    }

    return itemsMap;
  }

  double get totalCartPrice {
    return state.cartItems.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  Future<void> add(ShoppingItem item) async {
    repo.shopping.put(item);
    await refreshAll();
  }

  List<ShoppingItem> buildCartList(List<ShoppingItem> shoppingItems, List<ShoppingItem> cartItems) {
    final checkedItemsOnly = shoppingItems.where((item) => item.checked).toList();
    final checkedShoppingItemsByUid = checkedItemsOnly.toMap((item) => item.uid);
    final checkedShoppingItemsSet = checkedShoppingItemsByUid.keys.toSet();

    final existingCartItemsByUid = cartItems.toMap((item) => item.uid);
    final existingCartItemsSet = existingCartItemsByUid.keys.toSet();

    final uidsToAdd = checkedShoppingItemsSet.difference(existingCartItemsSet);
    final uidsToRemove = existingCartItemsSet.difference(checkedShoppingItemsSet);

    for (final uid in uidsToAdd) {
      final shoppingItem = checkedShoppingItemsByUid[uid];

      if (shoppingItem != null) {
        final newItem = shoppingItem.copyWith(listName: ShoppingListName.cart, checked: false);

        cartItems.add(newItem);
        repo.shopping.put(newItem);
      }
    }

    for (final uid in uidsToRemove) {
      // Verify that the item has a valid upc before removing; items
      // without a upc are manual items added by the user and shouldn't be
      // removed from the cart
      if (existingCartItemsByUid[uid]!.upc.isNotEmpty) {
        repo.shopping.deleteById(uid);
        cartItems.remove(existingCartItemsByUid[uid]);
      }
    }

    // Return the sorted cart items
    return sortList(cartItems);
  }

  Future<void> check(ShoppingItem item, bool checked) async {
    int itemIndex = state.shoppingItems.indexWhere((i) => i.uid == item.uid);

    if (itemIndex != -1) {
      var updatedItem = state.shoppingItems[itemIndex].copyWith(checked: checked);
      state.shoppingItems[itemIndex] = updatedItem;

      repo.shopping.put(updatedItem);

      // Rebuild the cart list
      final updatedCart = buildCartList(state.shoppingItems, state.cartItems);
      state = state.copyWith(
        shoppingItems: sortList(state.shoppingItems),
        cartItems: updatedCart,
      );
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
    final itemsByList = shoppingItemsByList;
    final shoppingList = itemsByList[ShoppingListName.shopping] ?? [];
    final savedItems = itemsByList[ShoppingListName.saved] ?? [];
    final cartItems = itemsByList[ShoppingListName.cart] ?? [];

    final updatedShoppingList = updateShoppingList(shoppingList);
    final updatedCart = buildCartList(updatedShoppingList, cartItems);

    state = state.copyWith(
      shoppingItems: updatedShoppingList,
      savedItems: sortList(savedItems),
      cartItems: updatedCart,
    );
  }

  Future<void> remove(ShoppingItem item) async {
    // If we have a upc, this was an automatically added item.
    // We need to remove it from the inventory database so it isn't re-added
    if (item.upc.isNotEmpty) {
      repo.inv.deleteById(item.upc);
    }

    repo.shopping.deleteById(item.uid);
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
        if (a.checked != b.checked) return a.checked ? 1 : -1;
        if (a.name.isEmpty) return 1;
        if (b.name.isEmpty) return -1;
        return a.name.compareTo(b.name);
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

  List<ShoppingItem> updateShoppingList(List<ShoppingItem> items) {
    final outs = this.outs();
    final outsUPCs = outs.map((item) => item.upc).toSet();

    // Remove items that are no longer considered outs and delete from the db
    items.removeWhere((item) {
      bool shouldRemove = item.upc.isNotEmpty && !outsUPCs.contains(item.upc);
      if (shouldRemove) {
        repo.shopping.deleteById(item.uid);
      }
      return shouldRemove;
    });

    // Create a set of all the upcs in the items
    final itemUPCs = items.map((item) => item.upc).toSet();

    // Add all the outs that are not already in the list
    for (final out in outs) {
      if (!itemUPCs.contains(out.upc)) {
        items.add(out);
      }
    }

    return sortList(items);
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
