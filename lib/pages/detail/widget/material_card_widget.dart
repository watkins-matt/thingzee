import 'package:flutter/material.dart';

class MaterialCardWidget extends StatelessWidget {
  final List<Widget> children;

  const MaterialCardWidget({
    Key? key,
    required this.children,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
