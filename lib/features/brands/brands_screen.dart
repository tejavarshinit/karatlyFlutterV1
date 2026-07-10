import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  static const _brands = [
    ('SafeGold', 'Trusted partner'),
    ('Augmont', 'Vault-backed'),
    ('Karatly Select', 'Premium line'),
    ('Hallmark Gold', 'Certified purity'),
    ('VaultEdge', 'Secure storage'),
    ('PureMint', 'Refined collection'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.97, -0.38),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text('Trusted Brands', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Brands we work with', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('A curated list of safe and trusted partners.', style: TextStyle(color: Color(0xFF9E9A94), fontSize: 13)),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: _brands.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.96,
                    ),
                    itemBuilder: (context, index) {
                      final item = _brands[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181A),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2E2E2E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: index.isEven
                                      ? [const Color(0xFFF7CD57), const Color(0xFFE5AF35)]
                                      : [const Color(0xFF6DD6FF), const Color(0xFF3AC7FF)],
                                ),
                              ),
                              child: const Icon(Icons.verified, color: Colors.black),
                            ),
                            const Spacer(),
                            Text(item.$1, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(item.$2, style: const TextStyle(color: Color(0xFF9E9A94), fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
