import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/ml/history_provider.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

final shoppingCartProvider = StateNotifierProvider<ShoppingCart, ShoppingCartState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return ShoppingCart(repo);
});

class ShoppingCart extends StateNotifier<ShoppingCartState> {
  final Repository repo;

  ShoppingCart(this.repo) : super(ShoppingCartState(items: []));

  void add(JoinedItem item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
  }

  void completeTrip() {
    final now = DateTime.now();

    for (final item in state.items) {
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
      HistoryProvider().updateHistory(newHistory);
    }

    state = state.copyWith(
      items: [],
    );
  }

  void remove(JoinedItem item) {
    state = state.copyWith(
      items: state.items..remove(item),
    );
  }

  void removeAt(int index) {
    state = state.copyWith(
      items: state.items..removeAt(index),
    );
  }
}

class ShoppingCartState {
  final List<JoinedItem> items;
  final Map<String, double> prices = {};

  ShoppingCartState({required this.items});

  ShoppingCartState copyWith({
    List<JoinedItem>? items,
  }) {
    return ShoppingCartState(
      items: items ?? this.items,
    );
  }
}
