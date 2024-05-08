import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/shopping/state/animation.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class AnimatedShoppingListView extends ConsumerStatefulWidget {
  const AnimatedShoppingListView({super.key});

  @override
  ConsumerState<AnimatedShoppingListView> createState() => _AnimatedShoppingListViewState();
}

class _AnimatedShoppingListViewState extends ConsumerState<AnimatedShoppingListView> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    final animationState = ref.watch(animationStateProvider);
    final uncheckedItems = ref.watch(shoppingListProvider.notifier).uncheckedItems;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        for (final item in animationState.itemsToRemove.reversed) {
          // Find the index from uncheckedItems where the uid matches
          final index = ref.watch(shoppingListProvider.notifier).calculateIndexRemovedFrom(item);
          listKey.currentState?.removeItem(
            index,
            (context, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: buildItem(context, ref, animation, index),
              );
            },
            duration: const Duration(milliseconds: 200),
          );

          Future.delayed(const Duration(milliseconds: 200), () {
            ref.read(shoppingListProvider.notifier).check(item, true);
          });
        }

        for (final item in animationState.itemsToAdd) {
          final index = ref.watch(shoppingListProvider.notifier).calculateInsertionIndex(item);
          listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 200));

          Future.delayed(const Duration(milliseconds: 200), () {
            ref.read(shoppingListProvider.notifier).check(item, false);
          });
        }
      } finally {
        ref.read(animationStateProvider.notifier).resetAnimationTriggers();
      }
    });

    return AnimatedList(
      key: listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: uncheckedItems.length,
      itemBuilder: (context, index, animation) => buildItem(context, ref, animation, index),
    );
  }

  Widget buildItem(BuildContext context, WidgetRef ref, Animation<double> animation, int index) {
    final item = ref.read(shoppingListProvider.select((value) => value.shoppingItems[index]));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => SizeTransition(
        sizeFactor: animation,
        child: AnimatedOpacity(
          opacity: animation.value,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      ),
      child: ShoppingListTile(
        item: item,
        checkbox: true,
        autoFocus: false,
        onChecked: (uid, checked) {
          if (checked) {
            ref.read(animationStateProvider.notifier).removeItem(item);
          }
        },
      ),
    );
  }
}
