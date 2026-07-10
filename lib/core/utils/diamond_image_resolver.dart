class DiamondImageResult {
  final String type; // 'image', 'iframe', 'video'
  final String url;
  final String? fullUrl;

  const DiamondImageResult({required this.type, required this.url, this.fullUrl});
}

class DiamondImageResolver {
  static const _imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'];
  static const _videoExtensions = ['.mp4', '.webm', '.ogg', '.mov', '.avi'];
  static const _viewmydiamondsHost = 'viewmydiamonds.com';

  static DiamondImageResult resolve({
    required String? imageUrl,
    required String? diamondImage,
    required String? videoUrl,
    required bool hasImage,
    required bool hasVideo,
  }) {
    final url = imageUrl ?? diamondImage ?? '';

    if (url.isEmpty) {
      return const DiamondImageResult(type: 'image', url: '');
    }

    if (url.contains(_viewmydiamondsHost)) {
      return DiamondImageResult(type: 'iframe', url: url);
    }

    final lower = url.toLowerCase();
    for (final ext in _videoExtensions) {
      if (lower.endsWith(ext)) {
        return DiamondImageResult(type: 'video', url: url);
      }
    }

    for (final ext in _imageExtensions) {
      if (lower.endsWith(ext)) {
        return DiamondImageResult(type: 'image', url: url);
      }
    }

    return DiamondImageResult(type: 'image', url: url);
  }

  static String resolveVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return '';
    return videoUrl;
  }
}
