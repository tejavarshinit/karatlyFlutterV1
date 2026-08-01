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
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                bottomChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF2E2E2E), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF202326)),
                          child: const Icon(Icons.access_time, color: Color(0xFFF7CD57), size: 18),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Session Policy', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('One active session per account', style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
              onTap: () => context.go(AppRoutes.profile),
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
    Widget? bottomChild,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Row(
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
                              borderRadius: BorderRadius.circular(20),
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
          if (bottomChild != null) bottomChild,
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
