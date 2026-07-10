import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/auth_provider.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final phoneNumber = authState.phoneNumber ?? 'Not set';
    final kycStatus = user?.kycStatus ?? 'Not Started';
    final kycApproved = user?.kycApproved ?? false;

    final badge = kycApproved
        ? _Badge(label: 'Verified', color: const Color(0xFF15EE01), bg: const Color(0xFF032101))
        : kycStatus.toLowerCase() == 'pending'
            ? _Badge(label: 'Pending', color: const Color(0xFFF7CD57), bg: const Color(0xFF1D170D))
            : _Badge(label: 'Not Started', color: const Color(0xFFFF5555), bg: const Color(0xFF1A0A0A));

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
              _buildSectionTitle('AUTHENTICATION'),
              const SizedBox(height: 12),
              _securityCard(
                icon: Icons.phone_outlined,
                title: 'Login Method',
                subtitle: 'Phone · $phoneNumber',
                badge: const _Badge(label: 'OTP Verified', color: Color(0xFF15EE01), bg: Color(0xFF032101)),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('KYC VERIFICATION'),
              const SizedBox(height: 12),
              _securityCard(
                icon: Icons.shield_outlined,
                title: 'KYC Status',
                subtitle: kycApproved ? 'Your identity is verified' : (kycStatus.toLowerCase() == 'pending' ? 'Verification in progress' : 'Complete KYC to unlock features'),
                badge: badge,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('SESSION'),
              const SizedBox(height: 12),
              _securityCard(
                icon: Icons.check_circle_outline,
                title: 'Active Session',
                subtitle: 'You are logged in on this device',
                badge: const _Badge(label: 'Active', color: Color(0xFF15EE01), bg: Color(0xFF032101)),
              ),
              const Divider(height: 1, color: Color(0xFF2E2E2E)),
              _securityCard(
                icon: Icons.access_time,
                title: 'Session Policy',
                subtitle: 'One active session per account',
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.login);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3700).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF3700).withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Color(0xFFFF3700), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF3700)),
                      ),
                    ],
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
            const Text('Security', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
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

  Widget _securityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    _Badge? badge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF202326)),
            child: Icon(icon, color: const Color(0xFFF7CD57), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(subtitle, style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 10)),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badge.bg.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge.label,
                          style: TextStyle(color: badge.color, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});
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
