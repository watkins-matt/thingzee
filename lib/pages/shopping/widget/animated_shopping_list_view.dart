import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class AnimatedShoppingListView extends ConsumerStatefulWidget {
  final List<ShoppingItem> items;

  const AnimatedShoppingListView({
    super.key,
    required this.items,
  });

  @override
  ConsumerState<AnimatedShoppingListView> createState() => _AnimatedShoppingListViewState();
}

class _AnimatedShoppingListViewState extends ConsumerState<AnimatedShoppingListView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: widget.items.length,
      itemBuilder: (context, index, animation) => _buildItem(context, index, animation),
    );
  }

  void insertItemAtIndex(int index, ShoppingItem item) {
    widget.items.insert(index, item);
    _listKey.currentState?.insertItem(index);
  }

  void removeItemByUid(String uid) {
    int index = widget.items.indexWhere((item) => item.uid == uid);
    if (index != -1) {
      widget.items.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(animation),
          child: ShoppingListTile(
              item: widget.items[index], // Use the item snapshot if necessary
              checkbox: true,
              autoFocus: false),
        ),
        duration: const Duration(milliseconds: 300), // Shorter, more typical duration
      );
    }
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    final item = widget.items[index];
    return SizeTransition(
      sizeFactor: animation,
      child: ShoppingListTile(
        item: item,
        checkbox: true,
        autoFocus: index == widget.items.length - 1,
        onChecked: (uid, checked) {
          if (checked) {
            removeItemByUid(uid);
          } else {
            insertItemAtIndex(index + 1, item.copyWith(checked: checked));
          }
        },
      ),
    );
  }
}
