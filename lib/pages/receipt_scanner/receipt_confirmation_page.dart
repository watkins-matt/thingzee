import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/receipt.dart';
import 'package:thingzee/pages/item_match/item_match_page.dart';

class ReceiptConfirmationPage extends ConsumerWidget {
  final Receipt receipt;
  const ReceiptConfirmationPage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Receipt Items'),
      ),
      body: ListView.builder(
        itemCount: receipt.items.length,
        itemBuilder: (context, index) {
          final item = receipt.items[index];
          bool matched = false;

          return ListTile(
            title: Text(item.name),
            subtitle: matched
                // ignore: dead_code
                ? const Text('Matched', style: TextStyle(color: Colors.green))
                : const Text('No Match', style: TextStyle(color: Colors.red)),
            onTap: () {
              if (!matched) {
                // Navigate to the ItemMatchPage when an item isn't matched
                ItemMatchPage.push(context, item);
              }
            },
          );
        },
      ),
    );
  }

  static Future<void> push(
    BuildContext context,
    Receipt receipt,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptConfirmationPage(receipt: receipt),
      ),
    );
  }

  static Future<void> pushReplacement(
    BuildContext context,
    Receipt receipt,
  ) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptConfirmationPage(receipt: receipt),
      ),
    );
  }
}
