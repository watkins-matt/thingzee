import 'package:flutter/material.dart';
import 'package:receipt_parser/model/receipt_item.dart';

class EditItemPriceDialog extends StatefulWidget {
  final ParsedReceiptItem item;
  final Function(ParsedReceiptItem) onItemEdited;

  const EditItemPriceDialog({super.key, required this.item, required this.onItemEdited});

  @override
  _EditItemPriceDialogState createState() => _EditItemPriceDialogState();
}

class _EditItemPriceDialogState extends State<EditItemPriceDialog> {
  late TextEditingController priceController;
  FocusNode priceFocusNode = FocusNode();
  late int quantity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            focusNode: priceFocusNode,
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => setState(() {
                  if (quantity > 0) quantity--;
                }),
              ),
              Text('$quantity'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() {
                  quantity++;
                }),
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            widget.onItemEdited(
              ParsedReceiptItem(
                name: widget.item.name,
                barcode: widget.item.barcode,
                quantity: quantity,
                price: double.tryParse(priceController.text) ?? widget.item.price,
                taxable: widget.item.taxable,
                bottleDeposit: widget.item.bottleDeposit,
              ),
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
    quantity = widget.item.quantity;

    // Set focus and select all text in the price field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      priceFocusNode.requestFocus();
      priceController.selection =
          TextSelection(baseOffset: 0, extentOffset: priceController.text.length);
    });
  }
}
