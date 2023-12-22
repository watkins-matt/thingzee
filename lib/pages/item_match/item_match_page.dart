import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';

class ItemMatchPage extends ConsumerStatefulWidget {
  final ReceiptItem receiptItem;
  const ItemMatchPage({super.key, required this.receiptItem});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ItemMatchPageState();

  static Future<void> push(BuildContext context, ReceiptItem receiptItem) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ItemMatchPage(receiptItem: receiptItem)),
    );
  }

  static Future<void> pushReplacement(BuildContext context, ReceiptItem receiptItem) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ItemMatchPage(receiptItem: receiptItem)),
    );
  }
}

class _ItemMatchPageState extends ConsumerState<ItemMatchPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<JoinedItem> items = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Match Item: ${widget.receiptItem.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                ref.read(inventoryProvider.notifier).search(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                JoinedItem item = items[index];
                return ListTile(
                  title: Text(item.item.name),
                  subtitle: Text(item.item.type),
                  trailing: Text('Qty: ${item.inventory.amount}'),
                  onTap: () {
                    // Handle item selection
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
