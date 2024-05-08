import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/shopping_item.dart';

final animationStateProvider = StateNotifierProvider<AnimationStateNotifier, AnimationState>((ref) {
  return AnimationStateNotifier();
});

class AnimationState {
  final List<ShoppingItem> itemsToAdd;
  final List<ShoppingItem> itemsToRemove;

  AnimationState({this.itemsToAdd = const [], this.itemsToRemove = const []});

  AnimationState copyWith({List<ShoppingItem>? itemsToAdd, List<ShoppingItem>? itemsToRemove}) {
    return AnimationState(
      itemsToAdd: itemsToAdd ?? this.itemsToAdd,
      itemsToRemove: itemsToRemove ?? this.itemsToRemove,
    );
  }
}

class AnimationStateNotifier extends StateNotifier<AnimationState> {
  AnimationStateNotifier() : super(AnimationState());

  void addItem(ShoppingItem item) {
    state = state.copyWith(
      itemsToAdd: List<ShoppingItem>.from(state.itemsToAdd)..add(item),
    );
  }

  void removeItem(ShoppingItem item) {
    state = state.copyWith(
      itemsToRemove: List<ShoppingItem>.from(state.itemsToRemove)..add(item),
    );
  }

  void resetAnimationTriggers() {
    state = state.copyWith(itemsToAdd: [], itemsToRemove: []);
  }
}
