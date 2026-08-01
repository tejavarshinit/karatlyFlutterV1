import 'package:flutter/material.dart';
import '../../../core/models/diamond_model.dart';
import '../../../core/utils/diamond_image_resolver.dart';
import 'diamond_iframe.dart';

/// 60x60 cart thumbnail that renders the actual diamond visual,
/// mirroring React's `CartItemThumb` (viewmydiamonds URLs load in an iframe).
class DiamondCartThumb extends StatefulWidget {
  final DiamondCartItem item;
  final Color placeholderColor;

  const DiamondCartThumb({
    super.key,
    required this.item,
    this.placeholderColor = const Color(0xFF3E3E3E),
  });

  @override
  State<DiamondCartThumb> createState() => _DiamondCartThumbState();
}

class _DiamondCartThumbState extends State<DiamondCartThumb> {
  late DiamondImageResult _resolved;
  String? _viewType;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final product = item.product;
    final rawUrl = item.imageUrl.isNotEmpty
        ? item.imageUrl
        : (product?.imageUrl.isNotEmpty == true
            ? product!.imageUrl
            : (product?.diamondImage ?? ''));

    _resolved = DiamondImageResolver.resolve(
      imageUrl: rawUrl,
      diamondImage: null,
      videoUrl: '',
      hasImage: rawUrl.isNotEmpty,
      hasVideo: false,
    );

    if (_resolved.type == 'iframe' && _resolved.url.isNotEmpty) {
      _viewType =
          'diamond-cart-${item.id}-${DateTime.now().microsecondsSinceEpoch}';
      DiamondIframeHelper.register(_viewType!, _resolved.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1A1A1A),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_resolved.type == 'iframe' && _viewType != null) {
      return DiamondIframeWidget(viewType: _viewType!, url: _resolved.url);
    }
    if (_resolved.type == 'image' && _resolved.url.isNotEmpty) {
      return Image.network(
        _resolved.url,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(shimmer: true);
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool shimmer = false}) {
    return Container(
      color: shimmer ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: Icon(
        Icons.diamond_outlined,
        size: 24,
        color: widget.placeholderColor.withValues(alpha: shimmer ? 0.4 : 1),
      ),
    );
  }
}
