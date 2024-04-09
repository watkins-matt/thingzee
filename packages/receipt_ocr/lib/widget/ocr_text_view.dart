import 'package:flutter/material.dart';

class OCRTextView extends StatelessWidget {
  final String text;

  const OCRTextView({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Text View')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(text),
        ),
      ),
    );
  }
}
