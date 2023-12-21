import 'package:flutter/material.dart';
import 'package:repository/model/receipt.dart';

class EditItemDialog extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onItemEdited;

  const EditItemDialog({super.key, required this.item, required this.onItemEdited});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController nameController;
  late TextEditingController barcodeController;
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late bool taxable;
  late double bottleDeposit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(nameController, 'Name')),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(barcodeController, 'Barcode')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField(quantityController, 'Quantity')),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(priceController, 'Price')),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SwitchListTile(
                title: const Text('Taxable'),
                value: taxable,
                onChanged: (bool value) {
                  setState(() {
                    taxable = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () => _changeBottleDeposit(context),
                child: const Text('Change Bottle Deposit'),
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
              ReceiptItem(
                name: nameController.text,
                barcode: barcodeController.text,
                quantity: int.tryParse(quantityController.text) ?? 1,
                price: double.tryParse(priceController.text) ?? 0.0,
                taxable: taxable,
                bottleDeposit: bottleDeposit,
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
    quantityController = TextEditingController(text: widget.item.quantity.toString());
    priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
    taxable = widget.item.taxable;
    bottleDeposit = widget.item.bottleDeposit;
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  void _changeBottleDeposit(BuildContext context) {}
}
