import 'package:flutter/material.dart';
import 'package:receipt_parser/model/receipt_item.dart';

class EditItemNameDialog extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onItemEdited;

  const EditItemNameDialog({super.key, required this.item, required this.onItemEdited});

  @override
  _EditItemNameDialogState createState() => _EditItemNameDialogState();
}

class _EditItemNameDialogState extends State<EditItemNameDialog> {
  late TextEditingController nameController;
  late TextEditingController barcodeController;
  FocusNode nameFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            focusNode: nameFocusNode,
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            keyboardType: TextInputType.text,
          ),
          TextField(
            controller: barcodeController,
            decoration: const InputDecoration(labelText: 'Barcode'),
            keyboardType: TextInputType.number,
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
              ReceiptItem(
                name: nameController.text,
                barcode: barcodeController.text,
                quantity: widget.item.quantity,
                price: widget.item.price,
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
    nameController = TextEditingController(text: widget.item.name);
    barcodeController = TextEditingController(text: widget.item.barcode);

    // Set focus and select all text in the name field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameFocusNode.requestFocus();
      nameController.selection =
          TextSelection(baseOffset: 0, extentOffset: nameController.text.length);
    });
  }
}
