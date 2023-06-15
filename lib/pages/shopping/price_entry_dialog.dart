import 'package:flutter/material.dart';
import 'package:money2/money2.dart';

class PriceEntryDialog extends StatefulWidget {
  const PriceEntryDialog({super.key});

  static Future<Money> show(BuildContext context) async {
    return await showDialog(context: context, builder: (context) => const PriceEntryDialog());
  }

  @override
  State<PriceEntryDialog> createState() => _PriceEntryDialogState();
}

class _PriceEntryDialogState extends State<PriceEntryDialog> {
  Money price = Money.fromInt(0, code: 'USD');
  final TextEditingController _controller = TextEditingController();
  bool taxable = false;
  bool crv = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Price: '),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: _controller,
            decoration: const InputDecoration(focusedBorder: UnderlineInputBorder()),
            // decoration: InputDecoration(labelText: 'Price'),
          ),
          CheckboxListTile(
            title: const Text('Taxable'),
            value: taxable,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                taxable = value ?? taxable;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('+CRV'),
            value: crv,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                crv = value ?? crv;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.pop(context, price);
            },
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            price = Money.parse(_controller.text, code: 'USD');
            Navigator.pop(context, price);
          },
          child: const Text('OK'),
        )
      ],
    );
  }
}
