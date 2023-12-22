import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/receipt.dart';
import 'package:thingzee/pages/receipt_scanner/edit_item_dialog.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/post_scan_handler.dart';
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
            // Text('Date: ${receipt.date}'),
            // Text('Item Count: ${receipt.items.length}'),
            // Text('Calculated Subtotal: \$${receipt.calculatedSubtotal.toStringAsFixed(2)}'),
            // if (receipt.subtotal > 0.0) Text('Subtotal: \$${receipt.subtotal.toStringAsFixed(2)}'),
            // if (receipt.discounts.isNotEmpty) Text('Discounts: \$${receipt.discounts.join(", ")}'),
            // if (receipt.tax > 0.0) Text('Tax: ${receipt.tax.toStringAsFixed(2)}%'),
            // if (receipt.total > 0.0) Text('Total: \$${receipt.total.toStringAsFixed(2)}'),
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
        _buildComparisonRow(context, ref, 'Item Count', receipt.items.length, receipt.items.length,
            isInt: true),
        _buildComparisonRow(context, ref, 'Subtotal', receipt.calculatedSubtotal, receipt.subtotal,
            isInt: false),
      ],
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
