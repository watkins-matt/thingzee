import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ImageBrowserPage extends StatefulWidget {
  final String upc;
  const ImageBrowserPage(this.upc, {super.key});

  @override
  State<ImageBrowserPage> createState() => _ImageBrowserPageState();

  static Future<String> push(BuildContext context, String upc) async {
    return await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ImageBrowserPage(upc)),
        ) ??
        '';
  }
}

class _ImageBrowserPageState extends State<ImageBrowserPage> {
  static const String imageSearchUrl = 'https://www.google.com/search?tbm=isch&q=';
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  late final TextEditingController urlController;
  String selectedUrl = '';

  @override
  Widget build(BuildContext context) {
    String query = Uri.encodeQueryComponent(widget.upc);
    String url = '$imageSearchUrl$query';

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          titleSpacing: 0,
          leadingWidth: 40,
          backgroundColor: Colors.white,
          leading: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: const Icon(Icons.cancel), color: Colors.red, onPressed: onCancelPressed)),
          title: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
            ),
            onSubmitted: onUrlSubmitted,
          ),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.blue,
                onPressed: onArrowBackPressed),
            IconButton(
                icon: const Icon(Icons.check_box),
                color: Colors.green,
                onPressed: onCheckboxPressed)
          ],
        ),
        body: Column(
          children: [
            Expanded(
                child: InAppWebView(
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              key: webViewKey,
              contextMenu: ContextMenu(
                  options: ContextMenuOptions(hideDefaultSystemContextMenuItems: false)),
              initialUrlRequest: URLRequest(url: Uri.parse(url)),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  useShouldOverrideUrlLoading: true,
                  javaScriptEnabled: true,
                  disableContextMenu: false,
                ),
                android: AndroidInAppWebViewOptions(
                  useHybridComposition: false,
                ),
              ),
              shouldOverrideUrlLoading: shouldOverrideUrlLoading,
              onLongPressHitTestResult: onLongPressHitTestResult,
            )),
          ],
        ));
  }

  @override
  void initState() {
    String query = Uri.encodeQueryComponent(widget.upc);
    String url = 'https://www.google.com/search?tbm=isch&q=$query';
    urlController = TextEditingController(text: url);
    super.initState();
  }

  Future<void> onArrowBackPressed() async {
    await webViewController?.goBack();

    final history = await webViewController?.getCopyBackForwardList();
    int currentIndex = history?.currentIndex ?? 0;
    int lastIndex = currentIndex > 0 ? currentIndex - 1 : 0;

    final historyItem = history?.list![lastIndex];
    final lastUrl = historyItem?.url;
    final lastUrlString = lastUrl?.toString() ?? '';

    if (lastUrlString.isNotEmpty) {
      urlController.text = lastUrlString;
    }
  }

  void onCancelPressed() {
    Navigator.pop(context);
  }

  void onCheckboxPressed() {
    Navigator.pop<String>(context, selectedUrl);
  }

  Future<void> onLongPressHitTestResult(
      InAppWebViewController controller, dynamic hitTestResult) async {
    var href = await controller.requestFocusNodeHref();
    final url = href?.src;

    if (url != null) {
      if (url.startsWith('data:image/jpeg') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Image not usable. Please follow the link to the website and try again on that image.')));
      } else {
        await controller.loadUrl(urlRequest: URLRequest(url: Uri.parse(url)));
        selectedUrl = url;
        urlController.text = url;
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No image found at selected point.'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  void onUrlSubmitted(String url) {
    if (url.isNotEmpty) {
      final parsedUrl = Uri.tryParse(url);
      if (parsedUrl != null) {
        webViewController?.loadUrl(urlRequest: URLRequest(url: parsedUrl));
      }
    }
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    final request = action.request;
    final string = request.url.toString();

    if (string.startsWith('http://')) {
      final newUrl = string.replaceFirst('http://', 'https://');
      await controller.stopLoading();
      await controller.loadUrl(urlRequest: URLRequest(url: Uri.parse(newUrl)));
      urlController.text = newUrl;
      return NavigationActionPolicy.CANCEL;
    } else {
      urlController.text = string;
    }

    return NavigationActionPolicy.ALLOW;
  }
}
