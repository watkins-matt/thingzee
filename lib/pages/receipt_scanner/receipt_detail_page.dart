import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/receipt_scanner/edit_item_dialog.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/post_scan_handler.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_confirmation_page.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_scanner.dart';
import 'package:thingzee/pages/receipt_scanner/state/editable_receipt.dart';

class ReceiptDetailsPage extends ConsumerWidget {
  final ReceiptParser parser;
  const ReceiptDetailsPage({super.key, required this.parser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(editableReceiptProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showInfoDialog(context, receipt),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              await ReceiptConfirmationPage.push(context, receipt);
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: receipt.items.length,
                itemBuilder: (context, index) {
                  final item = receipt.items[index];
                  return ListTile(
                    title: Text(item.name, style: const TextStyle(fontSize: 16)),
                    subtitle: Text('Barcode: ${item.barcode}'),
                    trailing: Text('x ${item.quantity} - \$${item.price.toStringAsFixed(2)}'),
                    onLongPress: () => _showLongPressMenu(context, ref, index),
                    onTap: () {
                      // Show the edit item dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return EditItemDialog(
                            item: item,
                            onItemEdited: (editedItem) {
                              ref
                                  .read(editableReceiptProvider.notifier)
                                  .updateItem(index, editedItem);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _buildComparisonTable(context, ref, receipt),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          onPressed: () => _scanAnotherPage(context),
          tooltip: 'Scan Another Page',
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  void confirmDelete(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                ref.read(editableReceiptProvider.notifier).deleteItem(index);
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
            ),
          ],
        );
      },
    );
  }

  TableRow _buildComparisonHeader() {
    return TableRow(
      children: [
        Container(), // Empty cell for the corner
        const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Calculated'))),
        const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Actual'))),
      ],
    );
  }

  TableRow _buildComparisonRow(
      BuildContext context, WidgetRef ref, String label, num calculatedValue, num actualValue,
      {required bool isInt}) {
    // Determine if the calculated and actual values match or are very close
    final difference = (calculatedValue - actualValue).abs();
    bool valuesMatch = difference < 0.001;

    // Decide the display format for actualValue
    String actualValueDisplay =
        isInt ? actualValue.toString() : '\$${actualValue.toStringAsFixed(2)}';
    String calculatedValueDisplay =
        isInt ? calculatedValue.toString() : '\$${calculatedValue.toStringAsFixed(2)}';

    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(label)),
        Center(
            child: Padding(padding: const EdgeInsets.all(8), child: Text(calculatedValueDisplay))),
        InkWell(
          onTap: () {
            _showEditActualValueDialog(context, ref, label, actualValue, isInt: isInt);
          },
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // To keep icon next to the text
                    children: [
                      Text(actualValueDisplay,
                          style: const TextStyle(decoration: TextDecoration.underline)),
                      const SizedBox(width: 8), // Space between text and icon
                      Icon(
                        valuesMatch ? Icons.check : Icons.close,
                        color: valuesMatch ? Colors.green : Colors.red,
                      )
                    ],
                  ))),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(BuildContext context, WidgetRef ref, Receipt receipt) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
      },
      children: [
        _buildComparisonHeader(),
        _buildComparisonRow(context, ref, 'Subtotal', receipt.calculatedSubtotal, receipt.subtotal,
            isInt: false),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(value),
        ),
      ],
    );
  }

  void _insertNewItem(BuildContext context, WidgetRef ref, int index, {required bool before}) {
    ReceiptItem newItem = const ReceiptItem(
      name: '',
      barcode: '',
      quantity: 1,
      price: 0,
      taxable: false,
      bottleDeposit: 0,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditItemDialog(
          item: newItem,
          onItemEdited: (editedItem) {
            // Call the insertItem method with the edited item
            ref
                .read(editableReceiptProvider.notifier)
                .insertItem(before ? index : index + 1, editedItem);
          },
        );
      },
    );
  }

  Future<void> _scanAnotherPage(BuildContext context) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScannerPage(
          postScanHandler: ParsingPostScanHandler(parser),
        ),
      ),
    );
  }

  void _showEditActualValueDialog(
      BuildContext context, WidgetRef ref, String label, num currentValue,
      {required bool isInt}) {
    TextEditingController controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: controller,
            keyboardType:
                isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Enter new value'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                num? newValue =
                    isInt ? int.tryParse(controller.text) : double.tryParse(controller.text);
                if (label == 'Item Count') {
                } else if (label == 'Subtotal' && newValue != null) {
                  ref.read(editableReceiptProvider.notifier).updateSubtotal(newValue.toDouble());
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, Receipt receipt) {
    // Format the date to a more readable form
    String formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(receipt.date);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Receipt Information'),
          content: SingleChildScrollView(
            child: Table(
              // Define column widths for alignment
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              // Add a border to the table for better visual separation
              border: TableBorder.all(color: Colors.grey, width: 0.5),
              children: [
                _buildTableRow('Date:', formattedDate),
                _buildTableRow('Item Count:', '${receipt.items.length}'),
                if (receipt.discounts.isNotEmpty)
                  _buildTableRow('Discounts:', '\$${receipt.discounts.join(", ")}'),
                _buildTableRow('Tax:', '${receipt.tax.toStringAsFixed(2)}%'),
                _buildTableRow('Total:', '\$${receipt.total.toStringAsFixed(2)}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showLongPressMenu(BuildContext context, WidgetRef ref, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Insert New Item Before'),
              onTap: () {
                Navigator.pop(context); // Close the menu
                _insertNewItem(context, ref, index, before: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Insert New Item After'),
              onTap: () {
                Navigator.pop(context); // Close the menu
                _insertNewItem(context, ref, index, before: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Item'),
              onTap: () {
                Navigator.pop(context); // Close the menu
                // Ask for confirmation first
                confirmDelete(context, ref, index);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> push(
    BuildContext context,
    WidgetRef ref,
    ReceiptParser parser,
  ) async {
    final receiptNotifier = ref.watch(editableReceiptProvider.notifier);
    receiptNotifier.copyFrom(parser.receipt);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReceiptDetailsPage(parser: parser)),
    );
  }

  static Future<void> pushReplacement(
    BuildContext context,
    WidgetRef ref,
    ReceiptParser parser,
  ) async {
    final receiptNotifier = ref.watch(editableReceiptProvider.notifier);
    receiptNotifier.copyFrom(parser.receipt);

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ReceiptDetailsPage(parser: parser)),
    );
  }
}
