import 'package:flutter/material.dart';
import 'diamond_iframe.dart';

class DiamondViewerModal extends StatefulWidget {
  final String url;
  final String title;

  const DiamondViewerModal({super.key, required this.url, required this.title});

  @override
  State<DiamondViewerModal> createState() => _DiamondViewerModalState();
}

class _DiamondViewerModalState extends State<DiamondViewerModal> {
  late String _viewType;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _viewType = 'diamond-viewer-${DateTime.now().millisecondsSinceEpoch}';
    DiamondIframeHelper.register(_viewType, widget.url);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          DiamondIframeWidget(viewType: _viewType, url: widget.url),
          if (_loading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF7CD57),
                  strokeWidth: 2,
                  backgroundColor: Color(0xFF2E2E2E),
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            right: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                child: const Icon(Icons.close, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
