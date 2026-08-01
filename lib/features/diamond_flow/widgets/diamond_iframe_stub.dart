import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class DiamondIframeHelper {
  static void register(String viewType, String url) {}
}

class DiamondIframeWidget extends StatefulWidget {
  final String viewType;
  final String url;
  const DiamondIframeWidget(
      {super.key, required this.viewType, required this.url});

  @override
  State<DiamondIframeWidget> createState() => _DiamondIframeWidgetState();
}

class _DiamondIframeWidgetState extends State<DiamondIframeWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
