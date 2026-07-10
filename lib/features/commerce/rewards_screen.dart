import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const _history = [
    {'name': 'Priya.s', 'date': '12 May', 'amount': '+₹100'},
    {'name': 'Rohan.K', 'date': '08 May', 'amount': '+₹100'},
    {'name': 'Diya.M', 'date': '06 May', 'amount': '+₹100'},
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 88),
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
                    const Text('Rewards & Refferals', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
                    const Spacer(),
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
                        child: const Icon(Icons.notifications_outlined, size: 14, color: Color(0xFFC1C1C1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _earningsCard(),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: _StatCard(value: '3', label: 'Friends')),
                    SizedBox(width: 12),
                    Expanded(child: _StatCard(value: '₹300', label: 'This Month')),
                    SizedBox(width: 12),
                    Expanded(child: _StatCard(value: 'Gold', label: 'Tier')),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1416),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your referral code', style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Text('HARI10KAR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                          IconButton(
                            onPressed: () async => Clipboard.setData(const ClipboardData(text: 'HARI10KAR')),
                            icon: const Icon(Icons.copy, color: Color(0xFFE5AF35), size: 18),
                          ),
                          IconButton(
                            onPressed: () => Share.share('Join Karatly with my referral code HARI10KAR'),
                            icon: const Icon(Icons.ios_share, color: Color(0xFFE5AF35), size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Friend gets ₹50 · You get ₹100 when they invest ₹500+',
                        style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('EARNING HISTORY', style: TextStyle(color: Color(0xFFBFBFBF), fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1416),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
                  ),
                  child: Column(
                    children: List.generate(_history.length, (index) {
                      final item = _history[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(item['date']!, style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 10)),
                                  ],
                                ),
                                const Spacer(),
                                Text(item['amount']!, style: const TextStyle(color: Color(0xFF0FA902), fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (index < _history.length - 1) const Divider(height: 1, color: Color(0xFF2E2E2E)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _earningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2A28), Color(0xFF6C5123)],
        ),
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFF7CD57),
            child: Icon(Icons.card_giftcard, color: Colors.black, size: 34),
          ),
          SizedBox(height: 16),
          Text('Total Earnings', style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 14)),
          SizedBox(height: 4),
          Text('₹420', style: TextStyle(color: Color(0xFFF7CD57), fontSize: 32, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('≈ 0.064g gold equivalent', style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 14)),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 10)),
        ],
      ),
    );
  }
}
