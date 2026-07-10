import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final int count;
  final IconData icon;
  final String purity;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.count,
    required this.icon,
    required this.purity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242320),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3B37)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2D2A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3D3B37)),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7CD57).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF7CD57).withOpacity(0.2)),
                  ),
                  child: Text(
                    purity,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF7CD57),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count items',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9A94)),
            ),
          ],
        ),
      ),
    );
  }
}
