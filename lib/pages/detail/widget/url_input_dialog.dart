import 'package:flutter/material.dart';

class UrlInputDialog extends StatefulWidget {
  final String? existingUrl;
  final Widget? customButton;
  final Future<String?> Function()? customButtonAction;

  const UrlInputDialog({
    super.key,
    this.existingUrl,
    this.customButton,
    this.customButtonAction,
  });

  @override
  State<UrlInputDialog> createState() => _UrlInputDialogState();

  static Future<String?> show(
    BuildContext context, {
    String? existingUrl,
    Widget? customButton,
    Future<String?> Function()? customButtonAction,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => UrlInputDialog(
        existingUrl: existingUrl,
        customButton: customButton,
        customButtonAction: customButtonAction,
      ),
    );
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
        minLines: 1,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'URL',
          errorText: _isUrlValid || !_hasStartedTyping ? null : 'Please enter a valid URL',
        ),
        keyboardType: TextInputType.url,
      ),
      actions: [
        if (widget.customButton != null && widget.customButtonAction != null)
          TextButton(
            child: widget.customButton!,
            onPressed: () async {
              final url = await widget.customButtonAction?.call();
              if (url != null && _validateUrl(url)) {
                _urlController.text = url;
                _urlController.selection = TextSelection.fromPosition(
                  TextPosition(offset: url.length),
                );
              }
            },
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Even if the user didn't start typing, force validation
            // when the submit button is pressed
            _hasStartedTyping = true;

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
      _isUrlValid = _validateUrl(widget.existingUrl!);
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
