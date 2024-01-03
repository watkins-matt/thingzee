import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserPage extends StatefulWidget {
  final String initialUrl;
  const BrowserPage(this.initialUrl, {super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();

  static Future<String> push(BuildContext context, String initialUrl) async {
    return await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BrowserPage(initialUrl)),
        ) ??
        '';
  }
}

class _BrowserPageState extends State<BrowserPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  late final TextEditingController urlController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
              hintText: 'Enter URL here',
            ),
            onSubmitted: onUrlSubmitted,
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onArrowBackPressed),
            IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  loadInitialUrl();
                })
          ],
        ),
        body: InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(url: Uri.parse(widget.initialUrl)),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true,
              javaScriptEnabled: true,
            ),
            android: AndroidInAppWebViewOptions(
              useHybridComposition: true,
            ),
          ),
          shouldOverrideUrlLoading: shouldOverrideUrlLoading,
        ));
  }

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(text: widget.initialUrl);
  }

  void loadInitialUrl() {
    loadUrl(widget.initialUrl);
  }

  void loadUrl(String url) {
    if (url.isNotEmpty) {
      final parsedUrl = Uri.tryParse(url);
      if (parsedUrl != null) {
        webViewController?.loadUrl(urlRequest: URLRequest(url: parsedUrl));
        urlController.text = parsedUrl.toString();
      }
    }
  }

  Future<void> onArrowBackPressed() async {
    await webViewController?.goBack();
    await updateUrlInController();
  }

  void onUrlSubmitted(String url) {
    loadUrl(url);
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    final request = action.request;
    final string = request.url.toString();

    if (string.startsWith('http://')) {
      final newUrl = string.replaceFirst('http://', 'https://');
      await controller.loadUrl(urlRequest: URLRequest(url: Uri.parse(newUrl)));
      urlController.text = newUrl;
      return NavigationActionPolicy.CANCEL;
    } else {
      urlController.text = string;
    }

    return NavigationActionPolicy.ALLOW;
  }

  Future<void> updateUrlInController() async {
    final url = await webViewController?.getUrl();
    if (url != null) {
      urlController.text = url.toString();
    }
  }
}
