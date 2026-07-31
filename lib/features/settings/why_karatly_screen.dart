import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class WhyKaratlyScreen extends StatelessWidget {
  const WhyKaratlyScreen({super.key});

  static const _features = [
    _FeatureData(Icons.calendar_view_day_outlined, 'Trusted Fintech Platform', 'Regulated and compliant with Indian financial standards, trusted by lakhs of users.'),
    _FeatureData(Icons.public, 'International Bullion Standards', 'Gold sourced and refined following internationally recognized bullion standards.'),
    _FeatureData(Icons.verified_outlined, 'Secure & Insured Vaults', 'Your gold is stored in world-class vaults with full insurance coverage.'),
    _FeatureData(Icons.phone_android, 'Easy Digital Transactions', 'Buy, sell, and manage your gold portfolio seamlessly from your smartphone.'),
    _FeatureData(Icons.trending_up, 'Long-Term Wealth Protection', 'Gold has been a proven wealth protector for centuries \u2014 now in digital form.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildTitle(),
                const SizedBox(height: 8),
                const Text(
                  'Karatly combines the timeless value of gold with the convenience of modern technology. Experience a new standard in digital gold investment.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E), height: 1.5),
                ),
                const SizedBox(height: 24),
                ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildFeatureCard(f),
                )),
                const SizedBox(height: 12),
                _buildStatsGrid(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go(AppRoutes.dashboard),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Why Karatly', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
          ],
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.notifications),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 14),
                const Positioned(right: 4, top: 4, child: SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEE0105), shape: BoxShape.circle)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WHY KARATLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFFF7CD57))),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'The Smarter Way to ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: 'Own Gold', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_FeatureData feature) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF7CD57).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: const Color(0xFFF7CD57), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text(feature.description, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: const [
          _StatCard(value: '99.99%', label: 'Gold Purity'),
          _StatCard(value: '100%', label: 'Vault Insurance'),
          _StatCard(value: '\u20b910', label: 'Min Investment'),
          _StatCard(value: 'Instant', label: 'Withdrawal'),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureData(this.icon, this.title, this.description);
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(color: Color(0xFFF7CD57), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
