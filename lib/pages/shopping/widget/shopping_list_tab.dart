import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/animated_shopping_list_view.dart';
import 'package:thingzee/pages/shopping/widget/custom_expansion_tile.dart';

class ShoppingListTab extends ConsumerStatefulWidget {
  const ShoppingListTab({super.key});

  @override
  ConsumerState<ShoppingListTab> createState() => _ShoppingListTabState();
}

class _ShoppingListTabState extends ConsumerState<ShoppingListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  Future<void> addNewItem(BuildContext context, WidgetRef ref) async {
    final shoppingList = ref.read(shoppingListProvider);
    final items = shoppingList.shoppingItems;

    if (items.isNotEmpty && items.last.name.isEmpty) {
      return;
    }

    final newItem = ShoppingItem(listName: ShoppingListName.shopping);
    await ref.read(shoppingListProvider.notifier).add(newItem);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final shoppingList = ref.watch(shoppingListProvider);
    final items = shoppingList.shoppingItems;

    return items.isEmpty
        ? const Center(
            child: Text(
              'You are not running out of anything yet.',
              style: TextStyle(fontSize: 18),
            ),
          )
        : SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                AnimatedShoppingListView(
                  filter: (item) => !item.checked,
                  editable: true,
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('List Item'),
                  onTap: () => addNewItem(context, ref),
                ),
                checkedItemsTile(context, ref),
              ],
            ),
          );
  }

  Widget checkedItemsTile(BuildContext context, WidgetRef ref) {
    final checkedItemsCount = ref.watch(
      shoppingListProvider
          .select((value) => value.shoppingItems.where((item) => item.checked).length),
    );

    return CustomExpansionTile(
      id: 'ShoppingList.checkedItems',
      title: Text('$checkedItemsCount Checked Items'),
      children: [
        AnimatedShoppingListView(
          filter: (item) => item.checked,
          editable: false,
        ),
      ],
      onExpansionChanged: (isExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
