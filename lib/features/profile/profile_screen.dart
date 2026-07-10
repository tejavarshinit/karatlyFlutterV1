import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/home_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import 'package:dio/dio.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  String? _aadhaarAddress;
  double _goldGrams = 0;
  double _silverGrams = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).fetchInvestmentData();
      _loadProfileData();
      _loadAadhaarAddressFromApi();
      _loadPassbookData();
    });
  }

  String _resolveUniqueId() {
    final authState = ref.read(authProvider);
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = profile['uniqueId']?.toString();
    if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    return '';
  }

  Future<void> _loadPassbookData() async {
    try {
      final uniqueId = _resolveUniqueId();
      if (uniqueId.isEmpty) return;
      final api = AugmontApi(ref.read(augmontDioProvider));
      final result = await api.fetchAugmontPassbook(uniqueId);
      if (result['ok'] == true && mounted) {
        final passbook = result['passbook'] as Map<String, dynamic>? ?? {};
        setState(() {
          _goldGrams = double.tryParse((passbook['goldGrms'] ?? passbook['goldBalance'] ?? passbook['balance'] ?? '0').toString()) ?? 0;
          _silverGrams = double.tryParse((passbook['silverGrms'] ?? passbook['silverBalance'] ?? '0').toString()) ?? 0;
        });
      }
    } catch (_) {}
  }

  void _loadProfileData() {
    final profile = LocalStorageService.getUserProfile();
    final address = profile?['aadhaarAddress']?.toString().trim();
    if (address != null && address.isNotEmpty) {
      setState(() => _aadhaarAddress = address);
    }
  }

  Future<void> _loadAadhaarAddressFromApi() async {
    try {
      final authState = ref.read(authProvider);
      final uniqueId = authState.user?.augmontUniqueId ?? LocalStorageService.getUserUniqueId();
      if (uniqueId == null || uniqueId.isEmpty) return;
      final api = AugmontApi(ref.read(augmontDioProvider));
      final response = await api.fetchAadhaarAddress(uniqueId: uniqueId);
      if (response['ok'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          final payload = data['payload'] as Map<String, dynamic>?;
          final result = payload?['result'] as Map<String, dynamic>?;
          final addressData = result?['data'] as Map<String, dynamic>? ?? result;
          final name = addressData?['name']?.toString() ?? '';
          final addressLine = addressData?['addressLine']?.toString() ?? addressData?['address']?.toString() ?? '';
          final fullAddress = [name, addressLine].where((s) => s.isNotEmpty).join('\n');
          if (fullAddress.isNotEmpty && mounted) {
            setState(() => _aadhaarAddress = fullAddress);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final rateState = ref.watch(rateProvider);
    final investment = homeState.investment;
    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;
    final portfolioValue = investment.goldHoldingWithMultiplier * goldRate
        + investment.silverHoldingWithMultiplier * silverRate;
    final name = authState.fullName ?? authState.user?.name ?? 'User';
    final phone = authState.phoneNumber ?? '';
    final email = authState.email ?? '';
    final profileStatus = _kycStatusLabel(authState.user?.kycStatus);

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
              _buildHeader(context, 'Profile'),
              const SizedBox(height: 22),
              _buildAvatar(authState, name),
              const SizedBox(height: 16),
              _buildUserInfo(name: name, phone: phone, email: email),
              const SizedBox(height: 24),
              _buildMetricsRow(
                goldGrams: _goldGrams,
                silverGrams: _silverGrams,
                portfolioValue: portfolioValue,
              ),
              const SizedBox(height: 22),
              _buildBoostTierBanner(context),
              if (_aadhaarAddress != null) ...[
                const SizedBox(height: 22),
                _buildDeliveryAddress(),
              ],
              const SizedBox(height: 22),
              _buildSectionHeading('ACCOUNT'),
              const SizedBox(height: 12),
              _buildKycRow(context, authState, profileStatus),
              _buildMenuRow(
                icon: Icons.account_balance_outlined,
                title: 'Add your bank',
                onTap: () => context.go(AppRoutes.paymentMethods),
              ),
              const SizedBox(height: 20),
              _buildSectionHeading('PREFERENCES'),
              const SizedBox(height: 12),
              _buildNotificationToggle(),
              _buildMenuRow(
                icon: Icons.shield_outlined,
                title: 'Security',
                onTap: () => context.go(AppRoutes.security),
              ),
              _buildMenuRow(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => context.go(AppRoutes.helpCenter),
              ),
              _buildMenuRow(
                icon: Icons.description_outlined,
                title: 'Terms & Condition',
                onTap: () => context.go(AppRoutes.terms),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Karatly v2.6.0 - Made with care',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),
              _buildSignOutButton(context, ref),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '9:30',
          style: TextStyle(fontSize: 12, color: Colors.white, height: 1.5),
        ),
        Row(
          children: [
            _statusIcon(width: 18, height: 12, child: const _SignalBars()),
            const SizedBox(width: 6),
            _statusIcon(width: 14, height: 12, child: const _WifiGlyph()),
            const SizedBox(width: 6),
            _statusIcon(width: 25, height: 12, child: const _BatteryGlyph()),
          ],
        ),
      ],
    );
  }

  Widget _statusIcon({
    required double width,
    required double height,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
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
            Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
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
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.go(AppRoutes.notifications),
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(AuthState authState, String name) {
    final photoBase64 = authState.user?.profilePhoto;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF7CD57), width: 2),
        ),
        child: ClipOval(
          child: photoBase64 != null && photoBase64.isNotEmpty
              ? Builder(
                  builder: (_) {
                    try {
                      final base64Data = photoBase64.contains(',') ? photoBase64.split(',').last : photoBase64;
                      return Image.memory(
                        base64Decode(base64Data),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => _buildInitial(initial),
                      );
                    } catch (_) {
                      return _buildInitial(initial);
                    }
                  },
                )
              : _buildInitial(initial),
        ),
      ),
    );
  }

  Widget _buildInitial(String initial) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7CD57), Color(0xFFB98324)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildUserInfo({
    required String name,
    required String phone,
    required String email,
  }) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 2),
        Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
      ],
    );
  }

  Widget _buildMetricsRow({
    required double goldGrams,
    required double silverGrams,
    required double portfolioValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.circle,
            iconColor: const Color(0xFFF7CD57),
            label: 'Gold',
            value: '${goldGrams.toStringAsFixed(2)} g',
            accentColor: const Color(0xFFF7CD57),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.circle,
            iconColor: const Color(0xFF90CAF9),
            label: 'Silver',
            value: '${silverGrams.toStringAsFixed(2)} g',
            accentColor: const Color(0xFF90CAF9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.trending_up,
            iconColor: const Color(0xFF66BB6A),
            label: 'Portfolio',
            value: _formatCurrency(portfolioValue),
            accentColor: const Color(0xFF66BB6A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
        ],
      ),
    );
  }

  Widget _buildBoostTierBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D170D), Color(0xFF0F1416)],
        ),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: Color(0xFFF7CD57), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boost Your Tier',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'Invest more to unlock exclusive benefits',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/buy/buy/1?metal=gold'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFD48D00)]),
              ),
              child: const Text(
                'Invest Now',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFFF7CD57), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBFBFBF)),
                ),
                const SizedBox(height: 4),
                Text(
                  _aadhaarAddress ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFBFBFBF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildKycRow(BuildContext context, AuthState authState, String profileStatus) {
    final isVerified = authState.user?.kycApproved ?? false;
    final badgeBg = isVerified ? const Color(0xFF0D3320) : const Color(0xFF3D2E00);
    final badgeColor = isVerified ? const Color(0xFF4CAF50) : const Color(0xFFF7CD57);

    return _buildMenuRow(
      icon: Icons.verified_user_outlined,
      title: 'KYC Verification',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
        child: Text(
          profileStatus,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor),
        ),
      ),
      onTap: () => context.go(AppRoutes.kycVerification),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: Color(0xFFF7CD57), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
            child: Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _notificationsEnabled ? const Color(0xFFF7CD57) : const Color(0xFF2E2E2E),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _notificationsEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF7CD57), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: Color(0xFF7E7E7E), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          ref.read(authProvider.notifier).logout();
          context.go(AppRoutes.login);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFFEF5350)),
          ),
          child: const Center(
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF5350)),
            ),
          ),
        ),
      ),
    );
  }

  String _kycStatusLabel(String? status) {
    final value = (status ?? '').trim().toLowerCase();
    if (value == 'approved' || value == 'verified') return 'Verified';
    if (value == 'pending') return 'Pending';
    return 'Not Started';
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }
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
  Widget build(BuildContext context) {
    return Container(width: 3, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1)));
  }
}

class _WifiGlyph extends StatelessWidget {
  const _WifiGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WifiPainter(),
    );
  }
}

class _WifiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
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
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BatteryPainter(),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, size.width - 4, size.height - 2), const Radius.circular(3));
    canvas.drawRRect(body, stroke);
    canvas.drawRect(Rect.fromLTWH(3, 3, size.width * 0.6, size.height - 6), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 2, 4, 2, size.height - 8), const Radius.circular(1)), fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
