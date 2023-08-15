import 'package:flutter/material.dart';

class ItemHeaderWidget extends StatelessWidget {
  final Widget image;
  final TextEditingController nameController;
  final void Function() onImagePressed;
  final void Function(String) onNameChanged;

  const ItemHeaderWidget({
    Key? key,
    required this.image,
    required this.nameController,
    required this.onImagePressed,
    required this.onNameChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        onTap: onImagePressed,
                        child: image,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 65,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextField(
                          decoration:
                              const InputDecoration(border: InputBorder.none, isCollapsed: true),
                          textAlign: TextAlign.left,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          controller: nameController,
                          onTap: () {
                            if (nameController.text == 'Unknown Item') {
                              nameController.selectAll();
                            }
                          },
                          onChanged: onNameChanged,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                          minLines: 1,
                          maxLines: null),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension SelectAllExtension on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}
