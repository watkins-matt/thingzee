import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PriceEntryDialog extends HookWidget {
  final double initialPrice;
  final int initialQuantity;
  final Function(double, int) onItemEdited;

  const PriceEntryDialog({
    super.key,
    required this.initialPrice,
    required this.initialQuantity,
    required this.onItemEdited,
  });

  @override
  Widget build(BuildContext context) {
    final priceController = useTextEditingController(text: initialPrice.toStringAsFixed(2));
    final priceFocusNode = useFocusNode();
    final quantity = useState<int>(initialQuantity);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        priceFocusNode.requestFocus();
        priceController.selection =
            TextSelection(baseOffset: 0, extentOffset: priceController.text.length);
      });
      return null;
    }, []);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            focusNode: priceFocusNode,
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (quantity.value > 0) quantity.value--;
                },
              ),
              Text('${quantity.value}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => quantity.value++,
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
            final double price = double.tryParse(priceController.text) ?? initialPrice;
            onItemEdited(price, quantity.value);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
