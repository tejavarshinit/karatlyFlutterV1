import 'package:flutter/material.dart';

class WhyKaratlyScreen extends StatelessWidget {
  const WhyKaratlyScreen({super.key});

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
                const SizedBox(height: 16),
                _buildHeader(context, 'Why Karatly'),
                const SizedBox(height: 32),
                _buildTitleSection(),
                const SizedBox(height: 24),
                _buildFeatureCard(
                  icon: Icons.verified_outlined,
                  title: 'Trusted Fintech',
                  description: 'RBI-compliant platform partnered with leading vault providers for secure gold transactions.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.public,
                  title: 'International Standards',
                  description: 'LBMA-accredited gold stored in internationally certified vaults meeting global quality standards.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.lock_outline,
                  title: 'Secure Vaults',
                  description: 'Your gold is stored in fully insured, multi-layered security vaults with 24/7 monitoring.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.phone_android,
                  title: 'Easy Digital',
                  description: 'Buy, sell, and manage gold anytime, anywhere with our intuitive mobile-first platform.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.savings_outlined,
                  title: 'Long-Term Wealth',
                  description: 'Gold has been a proven store of value for millennia. Build lasting wealth with systematic investments.',
                ),
                const SizedBox(height: 28),
                _buildStatsGrid(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFFF7CD57)),
            ),
          ],
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1D170D),
            border: Border.all(color: const Color(0xFFE8B438)),
          ),
          child: Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'The Smarter Way to ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Own Gold',
                style: TextStyle(
                  color: Color(0xFFF7CD57),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Discover why thousands of Indians trust Karatly for their gold investments.',
          style: TextStyle(
            color: Color(0xFF7E7E7E),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF202326),
            ),
            child: Icon(icon, color: const Color(0xFFF7CD57), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF7E7E7E),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: const [
        _StatCard(value: '99.99%', label: 'Purity'),
        _StatCard(value: '100%', label: 'Vault Insurance'),
        _StatCard(value: '₹10', label: 'Min Investment'),
        _StatCard(value: 'Instant', label: 'Withdrawal'),
      ],
    );
  }
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1F0A), Color(0xFF1D170D)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7CD57),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7E7E7E),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
