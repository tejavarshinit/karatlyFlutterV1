import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class TrademarkNoticeScreen extends StatelessWidget {
  const TrademarkNoticeScreen({super.key});

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
                SizedBox(
                  height: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        SizedBox(height: 16),
                        _buildBlockquote(),
                        SizedBox(height: 24),
                        _sectionTitle('1 TRADEMARK DETAILS'),
                        SizedBox(height: 12),
                        _trademarkTable(),
                        SizedBox(height: 24),
                        _sectionTitle('2 INTELLECTUAL PROPERTY \u2014 OWNERSHIP'),
                        SizedBox(height: 12),
                        _subsection('2.1 Platform Technology',
                            'All source code, APIs, algorithms, database architectures, UI/UX designs, and technology infrastructure underlying the Karatly Platform are the exclusive proprietary intellectual property of Karatly Finvest Technology India Private Limited.'),
                        SizedBox(height: 16),
                        _subsection('2.2 Content',
                            'All content on the Platform including website and app text, marketing copy, educational content, data compilations, and graphics are owned by or licensed to Karatly and protected under the Copyright Act, 1957.'),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
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
            const Text('Trademark Notice', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
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

  static Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trademark Notice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
        SizedBox(height: 4),
        Text('Proprietary Rights and Usage Guidelines', style: TextStyle(fontSize: 12, color: Color(0x80FFFFFF))),
      ],
    );
  }

  static Widget _buildBlockquote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: const Color(0xFFF7CD57).withOpacity(0.5), width: 4)),
      ),
      child: const Text(
        'The KARATLY trademark and logo have been applied for registration with the Office of the Controller General of Patents, Designs and Trade Marks (CGPDTM), Government of India. Karatly asserts full common-law trademark rights from the date of first use in commerce.',
        style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF), fontStyle: FontStyle.italic, height: 1.5),
      ),
    );
  }

  static Widget _trademarkTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _trademarkRow('Word Mark', 'KARATLY'),
          _divider(),
          _trademarkRow('Proprietor', 'Karatly Finvest Technology India Pvt Ltd'),
          _divider(),
          _trademarkRow('Class 36', 'Financial services \u2014 digital gold/silver savings, investment platform.'),
          _divider(),
          _trademarkRow('Class 9', 'Mobile applications, financial technology software.'),
        ],
      ),
    );
  }

  static Widget _trademarkRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 10, color: Color(0xB3FFFFFF), height: 1.4)),
          ),
        ],
      ),
    );
  }

  static Widget _divider() {
    return Divider(height: 1, color: Colors.white.withOpacity(0.05));
  }

  static Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.5));
  }

  static Widget _subsection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF), height: 1.6)),
      ],
    );
  }
}
