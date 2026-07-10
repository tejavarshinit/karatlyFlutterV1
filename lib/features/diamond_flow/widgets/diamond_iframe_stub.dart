import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DiamondIframeHelper {
  static void register(String viewType, String url) {}
}

class DiamondIframeWidget extends StatelessWidget {
  final String viewType;
  final String url;
  const DiamondIframeWidget({super.key, required this.viewType, required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    return WebViewWidget(controller: controller);
  }
}
