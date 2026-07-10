import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class DiamondIframeHelper {
  static void register(String viewType, String url) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = url;
      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });
  }
}

class DiamondIframeWidget extends StatelessWidget {
  final String viewType;
  final String url;
  const DiamondIframeWidget({super.key, required this.viewType, required this.url});

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewType);
  }
}
