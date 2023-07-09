import 'package:flutter/material.dart';

class TitleHeaderWidget extends StatelessWidget {
  final String title;
  final Widget? actionButton;

  const TitleHeaderWidget({
    Key? key,
    required this.title,
    this.actionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontSize: 20, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          actionButton ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
