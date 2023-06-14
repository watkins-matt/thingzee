import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/app.dart';

final shoppingCartProvider = StateNotifierProvider<ShoppingCart, ShoppingCartState>((ref) {
  return ShoppingCart(App.repo);
});

class ShoppingCart extends StateNotifier<ShoppingCartState> {
  final Repository repo;

  ShoppingCart(this.repo) : super(ShoppingCartState(items: []));

  void add(Item item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
  }

  void remove(Item item) {
    state = state.copyWith(
      items: state.items..remove(item),
    );
  }

  void removeAt(int index) {
    state = state.copyWith(
      items: state.items..removeAt(index),
    );
  }

  void completeTrip() {
    // TODO: Implement complete code
    //   for (final item in state.items) {
    //     final latestProduct = repo.p.get(item.upc); // Get the most recently updated item
    //     var newProduct = latestProduct.isPresent ? latestProduct.value : item;
    //     newProduct.lastUpdate = Optional.of(DateTime.now());

    //     // First update to the predicted amount so there is not confusion.
    //     if (newProduct.canPredictAmount) {
    //       newProduct.amount = newProduct.predictedAmount.roundToDouble();
    //     }

    //     newProduct.amount++;

    //     // Update the database with the new amount
    //     repo.p.put(newProduct);
    //   }

    //   state = state.copyWith(
    //     items: [],
    //   );
    // }
  }
}

class ShoppingCartState {
  final List<Item> items;

  ShoppingCartState({required this.items});

  ShoppingCartState copyWith({
    List<Item>? items,
  }) {
    return ShoppingCartState(
      items: items ?? this.items,
    );
  }
}
