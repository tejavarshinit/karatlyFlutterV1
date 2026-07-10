import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _openFaq;
  String _searchQuery = '';

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How is gold price calculated?',
      'answer':
          'Gold prices on Karatly are sourced from live international markets and updated in real-time. The price includes the base metal rate plus applicable taxes and a small making charge where relevant.',
    },
    {
      'question': 'How do I buy gold?',
      'answer':
          'Sign up, complete your KYC, add funds via UPI or net banking, and choose how much gold you want to buy. You can purchase gold starting from just ₹10.',
    },
    {
      'question': 'Is my gold safe?',
      'answer':
          'Yes. Your gold is stored in insured vaults managed by our trusted partners. Each gram is backed by physical gold and you can request physical delivery or sell it at any time.',
    },
    {
      'question': 'When does SIP debit happen?',
      'answer':
          'Your SIP amount is debited on the date you selected during setup. If the date falls on a weekend or holiday, the debit happens on the next working day.',
    },
    {
      'question': 'How do I redeem physical gold?',
      'answer':
          'You can redeem your digital gold for physical gold coins or bars from the Sell/Redeem section and have it delivered to your registered address.',
    },
    {
      'question': 'What are storage fees?',
      'answer':
          'Karatly provides secure storage for your digital gold. Any applicable storage or maintenance fees are shown before confirmation.',
    },
    {
      'question': 'How do I withdraw funds?',
      'answer':
          'Go to your dashboard, tap Withdraw, enter the amount you want to withdraw, and select your bank account. Funds are typically credited within 24-48 hours.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    final query = _searchQuery.toLowerCase();
    return _faqs.where((faq) {
      return faq['question']!.toLowerCase().contains(query) || faq['answer']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
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
                _buildStatusBar(),
                const SizedBox(height: 18),
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSearchCard(),
                const SizedBox(height: 28),
                _buildSectionTitle('CONTACT US'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _contactCard(
                        icon: Icons.phone_outlined,
                        label: 'Call Us',
                        value: '+919392918025',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _contactCard(
                        icon: Icons.mail_outline,
                        label: 'Mail Us',
                        value: 'Support@karatly.net',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('FAQ'),
                const SizedBox(height: 12),
                ..._filteredFaqs.asMap().entries.map((entry) {
                  final index = _faqs.indexOf(entry.value);
                  return _faqItem(
                    question: entry.value['question']!,
                    answer: entry.value['answer']!,
                    isOpen: _openFaq == index,
                    onTap: () {
                      setState(() {
                        _openFaq = _openFaq == index ? null : index;
                      });
                    },
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('9:30', style: TextStyle(fontSize: 12, color: Colors.white, height: 1.5)),
        Row(
          children: [
            _StatusGlyph(width: 18, child: _SignalBars()),
            SizedBox(width: 6),
            _StatusGlyph(width: 14, child: _WifiGlyph()),
            SizedBox(width: 6),
            _StatusGlyph(width: 25, child: _BatteryGlyph()),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Help Center', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
          ],
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.notifications),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 14),
                const Positioned(
                  right: 4,
                  top: 4,
                  child: SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEE0105), shape: BoxShape.circle))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFBFBFBF), letterSpacing: 1.2),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: const Icon(Icons.help_outline, color: Color(0xFFF7CD57), size: 22),
          ),
          const SizedBox(height: 12),
          const Text('How can we help?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF202326),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search for answers...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7E7E7E), size: 20),
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF202326)),
            child: Icon(icon, color: const Color(0xFFF7CD57), size: 18),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _faqItem({
    required String question,
    required String answer,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFFF7CD57), size: 20),
                ],
              ),
            ),
            if (isOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer,
                  style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 12, height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  final double width;
  final Widget child;
  const _StatusGlyph({required this.width, required this.child});
  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: 12, child: child);
}

class _SignalBars extends StatelessWidget {
  const _SignalBars();
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        _Bar(height: 4),
        SizedBox(width: 2),
        _Bar(height: 7),
        SizedBox(width: 2),
        _Bar(height: 10),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  const _Bar({required this.height});
  @override
  Widget build(BuildContext context) => Container(width: 3, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1)));
}

class _WifiGlyph extends StatelessWidget {
  const _WifiGlyph();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _WifiPainter());
}

class _WifiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(0, size.height * 0.15, 0, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7)
      ..quadraticBezierTo(size.width, size.height * 0.15, size.width / 2, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BatteryPainter());
}

class _BatteryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1;
    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, size.width - 4, size.height - 2), const Radius.circular(3)), stroke);
    canvas.drawRect(Rect.fromLTWH(3, 3, size.width * 0.6, size.height - 6), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 2, 4, 2, size.height - 8), const Radius.circular(1)), fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
