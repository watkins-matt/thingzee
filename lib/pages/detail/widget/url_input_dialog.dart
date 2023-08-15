import 'package:flutter/material.dart';

class UrlInputDialog extends StatefulWidget {
  final String? existingUrl;
  const UrlInputDialog({Key? key, this.existingUrl}) : super(key: key);

  @override
  State<UrlInputDialog> createState() => _UrlInputDialogState();

  static Future<String?> show(BuildContext context, {String? existingUrl}) async {
    final result = await showDialog<String>(
        context: context, builder: (context) => UrlInputDialog(existingUrl: existingUrl));
    return result;
  }
}

class _UrlInputDialogState extends State<UrlInputDialog> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isUrlValid = false;
  bool _hasStartedTyping = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure URL'),
      content: TextField(
        focusNode: _focusNode,
        controller: _urlController,
        decoration: InputDecoration(
          labelText: 'URL',
          errorText: _isUrlValid ? null : 'Please enter a valid URL',
        ),
        keyboardType: TextInputType.url,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final url = _urlController.text.trim();
            if (_validateUrl(url) && url.isNotEmpty) {
              Navigator.pop(context, url);
            } else {
              setState(() {
                _isUrlValid = false;
              });
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingUrl != null && widget.existingUrl!.isNotEmpty) {
      _urlController.text = widget.existingUrl!;
      _validateUrl(widget.existingUrl!);
    }
    _urlController.addListener(() {
      final url = _urlController.text.trim();
      if (url.isNotEmpty && !_hasStartedTyping) {
        _hasStartedTyping = true;
      }

      setState(() {
        _isUrlValid = _validateUrl(url);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  bool _validateUrl(String url) {
    if (!_hasStartedTyping) return true;
    if (url.isEmpty) return false;
    try {
      return Uri.parse(url).host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
