import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/custom_expansion_tile.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

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

    // Don't add a new item if the last item is already a new item
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
    final uncheckedItems = items.where((item) => !item.checked).toList();
    final checkedItems = items.where((item) => item.checked).toList();

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
                shoppingListViewBuilder(context, ref, uncheckedItems),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('List Item'),
                  onTap: () => addNewItem(context, ref),
                ),
                checkedItemsTile(context, ref, checkedItems),
              ],
            ),
          );
  }

  Widget checkedItemsTile(BuildContext context, WidgetRef ref, List<ShoppingItem> checkedItems) {
    return CustomExpansionTile(
      id: 'ShoppingList.checkedItems',
      title: Text('${checkedItems.length} Checked Items'),
      children: checkedItems.map((item) {
        return ShoppingListTile(
          item: item,
          editable: false,
          checkbox: true,
        );
      }).toList(),
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

  Widget shoppingListItemBuilder(
      BuildContext context, WidgetRef ref, ShoppingItem item, bool isLastItem) {
    bool shouldAutoFocus = isLastItem && item.name.isEmpty;
    return ShoppingListTile(item: item, editable: true, checkbox: true, autoFocus: shouldAutoFocus);
  }

  Widget shoppingListViewBuilder(BuildContext context, WidgetRef ref, List<ShoppingItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return shoppingListItemBuilder(
          context,
          ref,
          items[index],
          index == items.length - 1,
        );
      },
    );
  }
}
