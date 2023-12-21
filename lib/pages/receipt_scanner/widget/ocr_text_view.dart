import 'package:flutter/material.dart';

class OCRTextView extends StatelessWidget {
  final String text;

  const OCRTextView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Text View')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: SelectableText(text),
        ),
      ),
    );
  }
}
