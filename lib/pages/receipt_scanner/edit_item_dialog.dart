import 'package:flutter/material.dart';
import 'package:repository/model/receipt_item.dart';

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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _buildTextField(nameController, 'Name')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(barcodeController, 'Barcode',
                          keyboardType: TextInputType.number)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                      child: _buildTextField(quantityController, 'Quantity',
                          selectAllOnTap: true, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(priceController, 'Price',
                          selectAllOnTap: false, keyboardType: TextInputType.number)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          taxable = !taxable;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(taxable ? 'Taxable' : 'Not Taxable',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ElevatedButton(
                      onPressed: () => _changeBottleDeposit(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Bottle Deposit', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildTextField(TextEditingController controller, String label,
      {bool selectAllOnTap = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      onTap: selectAllOnTap
          ? () => controller.selection =
              TextSelection(baseOffset: 0, extentOffset: controller.text.length)
          : null,
    );
  }

  void _changeBottleDeposit(BuildContext context) {}
}
