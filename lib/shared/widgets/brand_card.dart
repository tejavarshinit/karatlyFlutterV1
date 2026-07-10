import 'package:flutter/material.dart';

class BrandCard extends StatelessWidget {
  final String name;
  final int trustScore;
  final bool verified;
  final String colorClass;
  final VoidCallback? onTap;

  const BrandCard({
    super.key,
    required this.name,
    required this.trustScore,
    required this.verified,
    required this.colorClass,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 144,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF242320),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3B37)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _parseColor(colorClass),
                    _parseColor(colorClass).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0] : '',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (verified)
                  const Icon(Icons.verified, size: 14, color: Color(0xFFF7CD57)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trust Score',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9E9A94)),
                ),
                Text(
                  '$trustScore%',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: trustScore / 100,
                backgroundColor: const Color(0xFF2E2D2A),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF7CD57)),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFFF7CD57);
    }
  }
}
