import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
              const SizedBox(height: 16),
              _buildInfoCard(),
              const SizedBox(height: 16),
              const Text(
                'These Terms and Conditions ("T&C") govern all transactions on the Karatly Platform. By clicking "I Agree" or placing any transaction, you agree to be bound by these T&C.',
                style: TextStyle(color: Color(0xFFBFBFBF), fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'TERMS AND CONDITIONS:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Container(
                height: 325,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1416),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                ),
                child: const SingleChildScrollView(
                  child: SelectableText(
                    _termsText,
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.45),
                  ),
                ),
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
            const Text('Terms & Condition', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
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

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2A28), Color(0xFF6C5123)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFF3C751), Color(0xFFBE8928)]),
            ),
            alignment: Alignment.center,
            child: const Text(
              'KARATLY',
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Karatly Legal v2.6', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Last updated June 2026', style: TextStyle(color: Color(0xFFBFBFBF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const String _termsText = '''
1 DEFINITIONS
Platform: www.karatly.net website and Karatly mobile application (iOS and Android).
GAP: Gold Accumulation Plan - digital gold/silver savings scheme powered by Augmont-Bullion.
Augmont-Bullion: Augmont Goldtech Private Limited - empanelled Bullion Partner and direct seller of Gold/Silver.
Sale Confirmation: Confirmation issued by Augmont-Bullion upon successful Gold/Silver purchase.
Live Rate - Purchase: Real-time Gold/Silver price per gram published by Augmont-Bullion.

2 ACCOUNT REGISTRATION AND KYC
• You must provide accurate, current, and complete information during registration.
• Mandatory two-factor KYC before any transaction: government-issued POI + POA + PAN + active Indian bank account + registered mobile number.
• PAN Card is mandatory for cumulative Gold/Silver purchases of Rs. 1,000 or more in a Financial Year.

3 PURCHASE AND IRREVOCABILITY
IRREVOCABILITY - Once Sale Confirmation is issued by Augmont-Bullion, the purchase is FINAL, BINDING, AND IRREVOCABLE. It cannot be cancelled, reversed, or suspended for any reason. The only exit from a confirmed position is the Sale-Back facility subject to the mandatory 48-hour holding period.

4 TITLE AND CUSTODY
Title and ownership of Gold/Silver purchased passes directly from Augmont-Bullion to the Customer at the moment of Sale Confirmation. Karatly never holds title to any Customer's Gold or Silver.

5 DELIVERY AND REDEMPTION
Customers may request physical delivery of Gold/Silver accumulated in their GAP account. Delivery is subject to making charges, delivery charges, and applicable taxes.

6 GOVERNING LAW
These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts located in Bangalore.
''';

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
