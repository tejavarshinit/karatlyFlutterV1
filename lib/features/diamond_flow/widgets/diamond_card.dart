import 'package:flutter/material.dart';
import '../../../core/models/diamond_model.dart';
import '../../../core/utils/diamond_image_resolver.dart';
import 'diamond_iframe.dart';
import 'diamond_viewer_modal.dart';

class DiamondCard extends StatefulWidget {
  final DiamondProduct product;
  final bool showVideo;
  final int quantity;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrement;

  const DiamondCard({
    super.key,
    required this.product,
    this.showVideo = false,
    this.quantity = 0,
    this.onAddToCart,
    this.onRemove,
    this.onIncrement,
  });

  @override
  State<DiamondCard> createState() => _DiamondCardState();
}

class _DiamondCardState extends State<DiamondCard> {
  DateTime? _lastTap;
  bool _addedToCart = false;
  late String _iframeViewType;

  @override
  void initState() {
    super.initState();
    _iframeViewType = 'diamond-card-${widget.product.productId}-${DateTime.now().millisecondsSinceEpoch}';
    _registerIframe();
  }

  void _registerIframe() {
    final product = widget.product;
    final imageResult = DiamondImageResolver.resolve(
      imageUrl: product.imageUrl,
      diamondImage: product.diamondImage,
      videoUrl: product.videoUrl,
      hasImage: product.hasImage,
      hasVideo: product.hasVideo,
    );

    String url;
    if (widget.showVideo && product.hasVideo && product.videoUrl.isNotEmpty) {
      url = '${product.videoUrl}?autoplay=1&mute=1';
    } else {
      url = imageResult.url;
    }

    DiamondIframeHelper.register(_iframeViewType, url);
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 300)) {
      _handleDoubleTap();
      _lastTap = null;
    } else {
      _lastTap = now;
    }
  }

  void _handleDoubleTap() {
    final videoUrl = DiamondImageResolver.resolveVideoUrl(widget.product.videoUrl);
    if (videoUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => DiamondViewerModal(
          url: videoUrl,
          title: '${widget.product.shape} ${widget.product.carat}ct ${widget.product.color} ${widget.product.clarity}',
        ),
      );
    }
  }

  void _handleAddToCart() {
    if (widget.onAddToCart == null) return;
    widget.onAddToCart!();
    setState(() => _addedToCart = true);
  }

  void _handleRemove() {
    widget.onRemove?.call();
    setState(() => _addedToCart = false);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageResult = DiamondImageResolver.resolve(
      imageUrl: product.imageUrl,
      diamondImage: product.diamondImage,
      videoUrl: product.videoUrl,
      hasImage: product.hasImage,
      hasVideo: product.hasVideo,
    );

    final inCart = widget.quantity > 0 || _addedToCart;
    final useIframe = imageResult.type == 'iframe' ||
        (widget.showVideo && product.hasVideo && product.videoUrl.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        color: const Color(0xFF26313B),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Video area
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.3, -0.3),
                    radius: 1.2,
                    colors: [Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
                  ),
                ),
                child: useIframe
                    ? _buildIframeArea(product, imageResult)
                    : _buildImageArea(imageResult),
              ),
            ),
          ),
          // Details
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Certificate badge with cert number
                  if (product.certificate.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0084FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.certificate} ${product.certNumber}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF3AC7FF), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    '${product.shape} ${product.carat.toStringAsFixed(2)}ct ${product.color} ${product.clarity}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Cut · Polish · Symmetry
                  if (product.cut.isNotEmpty)
                    Text(
                      '${product.cut} · ${product.polish} · ${product.symmetry}',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Shade and Luster Tags
                  if (product.shade.isNotEmpty || product.luster.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (product.shade.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              product.shade,
                              style: const TextStyle(fontSize: 9, color: Color(0xFFFBBF24)),
                            ),
                          ),
                        if (product.luster.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              product.luster,
                              style: const TextStyle(fontSize: 9, color: Color(0xFFC084FC)),
                            ),
                          ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Augmont India badge
                  const Text(
                    'Augmont India',
                    style: TextStyle(fontSize: 10, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(height: 4),

                  // Price in bordered box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2E2E2E)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${_formatPrice(product.finalPrice)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Add to Cart or Quantity Controls
                  if (!inCart)
                    _buildAddToCartButton()
                  else
                    _buildQuantityControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Iframe area (for viewmydiamonds.com + video — no CORS) ──────────────

  Widget _buildIframeArea(DiamondProduct product, DiamondImageResult imageResult) {
    return DiamondIframeWidget(viewType: _iframeViewType, url: imageResult.url);
  }

  // ─── Static image area (for direct image URLs) ───────────────────────────

  Widget _buildImageArea(DiamondImageResult imageResult) {
    if (imageResult.url.isNotEmpty) {
      return Image.network(
        imageResult.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.diamond_outlined, size: 32, color: Color(0xFF3E3E3E)),
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _handleAddToCart,
            child: const Center(
              child: Text(
                'Add to Cart',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF0084FF).withValues(alpha: 0.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          _buildCircleButton(
            icon: widget.quantity == 1 ? Icons.delete_outline : Icons.remove,
            color: widget.quantity == 1 ? const Color(0xFFEF4444) : const Color(0xFF3AC7FF),
            onTap: widget.quantity == 1 ? _handleRemove : widget.onRemove,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${widget.quantity}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          _buildCircleButton(
            icon: Icons.add,
            color: const Color(0xFF3AC7FF),
            onTap: widget.onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  String _formatPrice(double price) {
    final intValue = price.toInt();
    final buf = StringBuffer();
    final s = intValue.toString();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      count++;
      buf.write(s[i]);
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      } else if (count == 2 && i != 0 && s.length > 3) {
        final prev = i > 0 ? s[i - 1] : '';
        if (prev.isNotEmpty && prev != ',') {
          buf.write(',');
          count = 0;
        }
      }
    }
    return buf.toString().split('').reversed.join();
  }
}
