import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

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

  Future<void> check(String itemId) async {
    var item = state.shoppingItems.firstWhereOrNull((i) => i.uid == itemId);
    if (item != null) {
      final checkedItem = item.copyWith(checked: !item.checked);
      repo.shopping.put(checkedItem);

      if (checkedItem.checked) {
        var existingCartItem = state.cartItems.firstWhereOrNull((i) => i.uid == itemId);
        if (existingCartItem == null) {
          var newItem = checkedItem.copyWith(listName: ShoppingListName.cart);
          repo.shopping.put(newItem);
        }
      }
    }

    await refreshAll();
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

  Future<void> refreshAll() async {
    final allItems = repo.shopping.all();
    state = state.copyWith(
      shoppingItems: sortItems(allItems, ShoppingListName.shopping),
      savedItems: sortItems(allItems, ShoppingListName.saved),
      cartItems: sortItems(allItems, ShoppingListName.cart),
    );
  }

  Future<void> remove(String itemId) async {
    repo.shopping.deleteById(itemId);
    await refreshAll();
  }

  // Helper function to sort and filter items based on listName and checked status
  List<ShoppingItem> sortItems(List<ShoppingItem> items, String listName) {
    var filtered = items.where((item) => item.listName == listName).toList();
    filtered.sort((a, b) {
      // Move checked items to the end
      if (a.checked == b.checked) {
        return a.name.compareTo(b.name); // Then sort alphabetically by name
      }
      return a.checked ? 1 : -1;
    });
    return filtered;
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
