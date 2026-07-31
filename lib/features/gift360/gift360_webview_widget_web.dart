import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import '../../app/router.dart';

/// Web implementation: opens Gift360 in a new browser tab.
///
/// Gift360's server sends `X-Frame-Options: sameorigin` which blocks iframe
/// embedding in browsers. Native mobile WebViews are not affected.
/// On web, the best UX is to redirect to a new tab.
class Gift360WebViewWidget extends StatefulWidget {
  final String initialUrl;
  final VoidCallback? onPageStarted;
  final VoidCallback? onPageFinished;
  final void Function(dynamic)? onError;
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageStarted?.call();
      _launchInNewTab();
    });
  }

  void _launchInNewTab() {
    final url = widget.initialUrl;
    try {
      web.window.open(url, '_blank');
    } catch (_) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> canGoBack() async => false;

  Future<void> goBack() async {}

  Future<void> reload() async {
    _launchInNewTab();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: Color(0xFFF7CD57)),
            const SizedBox(height: 24),
            const Text(
              'Open Gift360 in Browser',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gift360 has been opened in a new browser tab.\nReturn here when you\'re done.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _launchInNewTab,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFD48D00)]),
                ),
                child: const Text('Open Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => GoRouter.of(context).go(AppRoutes.home),
              child: const Text('Go Back Home', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}
