import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Gift360WebViewWidget extends StatefulWidget {
  final String initialUrl;
  final VoidCallback? onPageStarted;
  final VoidCallback? onPageFinished;
  final void Function(dynamic error)? onError;
  final bool Function()? onBackRequested;

  const Gift360WebViewWidget({
    super.key,
    required this.initialUrl,
    this.onPageStarted,
    this.onPageFinished,
    this.onError,
    this.onBackRequested,
  });

  @override
  Gift360WebViewWidgetState createState() => Gift360WebViewWidgetState();
}

class Gift360WebViewWidgetState extends State<Gift360WebViewWidget> {
  WebViewController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
    });
  }

  Future<void> _initController() async {
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1117))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          debugPrint('Gift360: onPageStarted');
          widget.onPageStarted?.call();
        },
        onPageFinished: (_) {
          debugPrint('Gift360: onPageFinished');
          widget.onPageFinished?.call();
        },
        onWebResourceError: (error) {
          debugPrint('Gift360: onWebResourceError type=${error.errorType?.name} desc=${error.description}');
          widget.onError?.call(error);
        },
        onNavigationRequest: (req) {
          debugPrint('Gift360: navigation -> ${req.url}');
          return NavigationDecision.navigate;
        },
      ));
    await ctrl.loadRequest(Uri.parse(widget.initialUrl));
    if (mounted) {
      setState(() {
        _controller = ctrl;
        _initialized = true;
      });
    }
  }

  Future<bool> canGoBack() async {
    if (_controller == null) return false;
    return _controller!.canGoBack();
  }

  Future<void> goBack() async {
    if (_controller != null) {
      await _controller!.goBack();
    }
  }

  Future<void> reload() async {
    if (_controller != null) {
      await _controller!.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const SizedBox.shrink();
    }
    return WebViewWidget(controller: _controller!);
  }
}
