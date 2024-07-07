import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/shopping_item.dart';
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
    final uncheckedItems = ref.watch(shoppingListProvider
        .select((value) => value.shoppingItems.where((item) => !item.checked).toList()));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        for (final item in animationState.itemsToRemove.reversed) {
          final index = uncheckedItems.indexWhere((i) => i.uid == item.uid);
          if (index != -1) {
            listKey.currentState?.removeItem(
              index,
              (context, animation) => buildItem(context, ref, animation, item),
              duration: const Duration(milliseconds: 100),
            );
          }
          ref.read(shoppingListProvider.notifier).check(item, true);
        }

        for (final item in animationState.itemsToAdd) {
          final index = ref.read(shoppingListProvider.notifier).calculateInsertionIndex(item);
          listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 100));
          ref.read(shoppingListProvider.notifier).check(item, false);
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
      itemBuilder: (context, index, animation) {
        if (index < 0 || index >= uncheckedItems.length) {
          return const SizedBox.shrink(); // Return an empty widget if the index is out of range
        }
        return buildItem(context, ref, animation, uncheckedItems[index]);
      },
    );
  }

  Widget buildItem(
      BuildContext context, WidgetRef ref, Animation<double> animation, ShoppingItem item) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => SizeTransition(
        sizeFactor: animation,
        child: AnimatedOpacity(
          opacity: animation.value,
          duration: const Duration(milliseconds: 100),
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
