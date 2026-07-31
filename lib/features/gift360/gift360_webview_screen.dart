import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/router.dart';
import '../../core/api/config.dart';
import 'gift360_webview_widget.dart';

class Gift360WebViewScreen extends StatefulWidget {
  const Gift360WebViewScreen({super.key});

  @override
  State<Gift360WebViewScreen> createState() => _Gift360WebViewScreenState();
}

class _Gift360WebViewScreenState extends State<Gift360WebViewScreen> {
  final _webViewKey = GlobalKey<Gift360WebViewWidgetState>();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  void _handleBack() {
    final state = _webViewKey.currentState;
    if (state != null) {
      final future = state.canGoBack();
      future.then((canGoBack) {
        if (canGoBack) {
          state.goBack();
        } else {
          GoRouter.of(context).go(AppRoutes.home);
        }
      });
    } else {
      GoRouter.of(context).go(AppRoutes.home);
    }
  }

  void _reload() {
    _webViewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Color(0xFF2E2E2E), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC1C1C1), size: 18),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Gift360', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2E00),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFF7CD57).withValues(alpha: 0.4)),
            ),
            child: const Text('UAT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _reload,
            child: const Icon(Icons.refresh, color: Color(0xFFC1C1C1), size: 18),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: const Icon(Icons.close, color: Color(0xFFC1C1C1), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        Gift360WebViewWidget(
          key: _webViewKey,
          initialUrl: ApiConfig.gift360BaseUrl,
          onPageStarted: () => debugPrint('Gift360: page started'),
          onPageFinished: () {
            debugPrint('Gift360: page finished');
            setState(() => _isLoading = false);
          },
          onError: (error) {
            final e = error;
            final type = (e is WebResourceError) ? (e.errorType?.name ?? '') : '';
            final desc = (e is WebResourceError) ? e.description : '';
            debugPrint('Gift360 WebView error: type=$type, desc=$desc');

            final isFatal = type.contains('ssl') ||
                type.contains('host') ||
                (type.contains('connect') && !desc.contains('net::'));
            if (isFatal) {
              setState(() {
                _hasError = true;
                _isLoading = false;
                _errorMessage = _describeError(error);
              });
            }
          },
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  String _describeError(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again.';
    if (error is! WebResourceError) return 'Something went wrong. Please try again.';
    try {
      final type = error.errorType?.name ?? '';
      if (type.contains('host')) return 'Could not reach Gift360. Check your internet connection.';
      if (type.contains('connect') || type.contains('timeout')) return 'Connection lost. Please try again.';
      if (type.contains('ssl')) return 'SSL certificate error. Gift360 may not be configured for HTTPS properly.';
      if (error.description.isNotEmpty) return error.description;
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFF0D1117),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFF7CD57), strokeWidth: 3),
            SizedBox(height: 16),
            Text('Loading Gift360...', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFF7CD57)),
            const SizedBox(height: 16),
            const Text('Unable to load Gift360', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Please check your connection and try again.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _reload,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFD48D00)]),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
