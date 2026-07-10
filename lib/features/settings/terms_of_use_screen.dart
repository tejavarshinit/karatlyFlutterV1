import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _buildMetadataGrid(),
              const SizedBox(height: 20),
              _buildBlockquote(),
              const SizedBox(height: 24),
              _buildSection(
                'About Karatly',
                'Karatly is a digital platform that enables users to buy, sell, hold, and manage 24-karat gold through a transparent, technology-driven approach.',
              ),
              _buildSection(
                'Who Can Use',
                'Karatly is available to Indian citizens and residents who are at least 18 years of age and have a valid PAN card and Aadhaar number for KYC verification.',
              ),
              _buildSection(
                "Karatly's Role",
                'Karatly acts as a technology platform and intermediary connecting users with gold storage and transaction services. Karatly is not a bank, NBFC, or financial advisor.',
              ),
            ],
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
            const Text('Terms of Use', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
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

  Widget _buildMetadataGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: const Column(
        children: [
          _MetaRow(label: 'Effective Date', value: 'June 1, 2026'),
          SizedBox(height: 8),
          _MetaRow(label: 'Version', value: '2.6'),
          SizedBox(height: 8),
          _MetaRow(label: 'Platform', value: 'Karatly Mobile & Web'),
          SizedBox(height: 8),
          _MetaRow(label: 'Contact', value: 'support@karatly.net'),
        ],
      ),
    );
  }

  Widget _buildBlockquote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416).withOpacity(0.5),
        border: Border(left: BorderSide(color: const Color(0xFFF7CD57).withOpacity(0.6), width: 3)),
      ),
      child: const Text(
        '"By using Karatly, you agree to these Terms of Use and our Privacy Policy. These terms constitute a legally binding agreement between you and Karatly."',
        style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 12, fontStyle: FontStyle.italic, height: 1.6),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
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
