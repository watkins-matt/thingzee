import 'package:flutter/material.dart';

class MaterialCardWidget extends StatelessWidget {
  final List<Widget> children;
  final int padding;

  const MaterialCardWidget({
    super.key,
    required this.children,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: EdgeInsets.all(padding.toDouble()),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
