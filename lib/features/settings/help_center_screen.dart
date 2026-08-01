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
  final _searchController = TextEditingController();

  String get _query => _searchQuery.trim().toLowerCase();

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How is gold price calculated?',
      'answer':
          'The gold price displayed on Karatly is based on live market rates provided by our trusted bullion partners. Prices may change throughout the day depending on market movement, taxes, and applicable charges.',
    },
    {
      'question': 'How do I buy gold?',
      'answer':
          'Go to dashboard \u2192 enter amount or weight \u2192 click buy. Gold is instantly added to your digital vault upon successful payment.',
    },
    {
      'question': 'Is my gold safe?',
      'answer':
          'Yes, your gold is stored in world-class, insured vaults with 100% security and is fully backed by physical gold.',
    },
    {
      'question': 'When does SIP debit happen?',
      'answer':
          'Your SIP amount is debited on the scheduled date selected during SIP setup. If the debit fails due to insufficient balance or any payment issue, the transaction may not be processed. You can retry or update your payment method.',
    },
    {
      'question': 'How do I redeem physical gold?',
      'answer':
          'You can redeem your digital gold for physical gold from the redemption section. Select an eligible product, choose the quantity, add or confirm your delivery address, and submit the redemption request. Delivery timelines and applicable charges will be shown during checkout.',
    },
    {
      'question': 'What are storage fees?',
      'answer':
          'Your digital gold purchased through Karatly is securely stored with our vaulting partner. Any applicable storage charges, if any, will be shown as per the product terms and pricing details available in the app.',
    },
    {
      'question': 'How do I withdraw funds?',
      'answer':
          'To withdraw funds, sell your digital gold or silver holdings first. Once the sale is completed, the proceeds will be credited to your registered bank account as per the standard settlement timeline.',
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    if (_query.isEmpty) return _faqs.asMap().entries.map((e) => {'index': e.key, 'question': e.value['question'], 'answer': e.value['answer'], 'matchQ': true, 'matchA': true}).toList();
    return _faqs.asMap().entries.where((e) {
      final matchQ = e.value['question']!.toLowerCase().contains(_query);
      final matchA = e.value['answer']!.toLowerCase().contains(_query);
      return matchQ || matchA;
    }).map((e) {
      final matchQ = e.value['question']!.toLowerCase().contains(_query);
      final matchA = e.value['answer']!.toLowerCase().contains(_query);
      return {'index': e.key, 'question': e.value['question'], 'answer': e.value['answer'], 'matchQ': matchQ, 'matchA': matchA};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    if (_query.isNotEmpty && filtered.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _openFaq != filtered[0]['index']) {
          setState(() => _openFaq = filtered[0]['index']);
        }
      });
    }

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
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchCard(),
                  const SizedBox(height: 24),
                  _buildContactUs(),
                  const SizedBox(height: 24),
                  _buildFaqSection(filtered),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.profile),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
                ),
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
                    child: SizedBox(
                      width: 5,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEE0105),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1416),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFBBF42), Color(0xFFE59700)],
                ),
              ),
              child: CustomPaint(
                painter: _HelpIconPainter(),
                size: const Size(24, 24),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How can we help?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search articles...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4E4E4E), size: 18),
                  hintStyle: const TextStyle(color: Color(0xFF4E4E4E), fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactUs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('CONTACT US'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _contactCard(
                icon: Icons.phone_outlined,
                title: 'Call Us at',
                subtitle: '+919392918025',
              )),
              const SizedBox(width: 12),
              Expanded(child: _contactCard(
                icon: Icons.mail_outline,
                title: 'Mail Us at',
                subtitle: 'Support@karatly.net',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2A2923),
            ),
            child: Icon(icon, color: const Color(0xFFE5AF35), size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection(List<Map<String, dynamic>> filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('FAQ'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1416),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Column(
              children: [
                if (filtered.isEmpty && _query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No results found for "${_searchQuery.trim()}"',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...List.generate(filtered.length, (i) {
                  final item = filtered[i];
                  final idx = item['index'] as int;
                  final isOpen = _openFaq == idx;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _openFaq = isOpen ? null : idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildHighlightedText(
                                  item['question'] as String,
                                  item['matchQ'] as bool,
                                ),
                              ),
                              AnimatedRotation(
                                turns: isOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.expand_more, color: Color(0xFFBCBCBC), size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOpen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: _buildHighlightedText(
                            item['answer'] as String,
                            item['matchA'] as bool,
                            style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF9E9E9E)),
                          ),
                        ),
                      if (i < filtered.length - 1)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          height: 1,
                          color: const Color(0xFF2E2E2E),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, bool hasMatch, {TextStyle? style}) {
    if (!hasMatch || _query.isEmpty) {
      return Text(text, style: style ?? const TextStyle(fontSize: 14, color: Color(0xFFD5D5D5)));
    }
    final lower = text.toLowerCase();
    final spans = <InlineSpan>[];
    var lastIndex = 0;
    var idx = lower.indexOf(_query);
    while (idx != -1) {
      if (idx > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + _query.length),
        style: const TextStyle(backgroundColor: Color(0x40F7CD57), color: Color(0xFFF7CD57)),
      ));
      lastIndex = idx + _query.length;
      idx = lower.indexOf(_query, lastIndex);
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    return RichText(
      text: TextSpan(style: style ?? const TextStyle(fontSize: 14, color: Color(0xFFD5D5D5)), children: spans),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFFBFBFBF),
      ),
    );
  }
}

class _HelpIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2.4;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(centerX - radius * 0.35, centerY - radius * 0.35)
      ..lineTo(centerX + radius * 0.2, centerY + radius * 0.05);

    canvas.drawPath(path, strokePaint);

    canvas.drawCircle(
      Offset(centerX + radius * 0.15, centerY + radius * 0.35),
      1.2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
