import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import 'widgets/animated_ring_logo.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String mobileNumber;
  final String type;
  final String email;
  final String fullName;
  final String dateOfBirth;

  const OtpScreen({
    super.key,
    required this.mobileNumber,
    this.type = 'login',
    this.email = '',
    this.fullName = '',
    this.dateOfBirth = '',
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  bool _showKycPrompt = false;

  String get _maskedPhone {
    if (widget.mobileNumber.isEmpty) return '+91 98*****10';
    final phone = widget.mobileNumber;
    return '+91 ${phone.substring(0, 2)}*****${phone.substring(phone.length - 2)}';
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _error = null;
    });
    for (final c in _controllers) {
      c.clear();
    }
    try {
      await ref.read(authProvider.notifier).sendOtp(
        mobileNumber: widget.mobileNumber,
        email: widget.type == 'register' ? widget.email : '',
        fullName: widget.fullName.isNotEmpty ? widget.fullName : null,
        type: widget.type,
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 4 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).verifyOtp(
        mobileNumber: widget.mobileNumber,
        otp: otp,
        email: widget.email,
        fullName: widget.fullName.isNotEmpty ? widget.fullName : null,
        dateOfBirth: widget.dateOfBirth.isNotEmpty ? widget.dateOfBirth : null,
        type: widget.type,
      );

      if (mounted) {
        if (result['ok'] == true) {
          if (widget.type == 'register') {
            await _createAugmontUser();
          }
          if (!mounted) return;
          await _promptBiometricSetup();
          if (!mounted) return;
          final authState = ref.read(authProvider);
          final kycStatus = authState.user?.kycApproved == true || (authState.user?.kycStatus ?? '').toLowerCase() == 'approved';
          if (!kycStatus) {
            setState(() => _showKycPrompt = true);
          } else {
            if (mounted) context.go(AppRoutes.home);
          }
        } else {
          setState(() => _error = _friendlyError(result['message']?.toString() ?? 'Verification failed'));
        }
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('otp not match')) return 'Incorrect OTP. Please try again.';
    if (lower.contains('otp_already_verified')) return 'This OTP has already been used. Request a new one.';
    if (lower.contains('invalid_otp')) return 'Invalid OTP';
    if (lower.contains('expired')) return 'OTP has expired. Please request a new one.';
    return raw.isEmpty ? 'Verification failed. Please try again.' : raw;
  }

  Future<void> _promptBiometricSetup() async {
    try {
      final biometric = BiometricAuthService();
      if (!mounted || await biometric.isEnabled()) return;

      final enable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1918),
          title: const Text('Quick Login', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Use fingerprint, face, or PIN to login next time.',
            style: TextStyle(color: Color(0xFF9E9A94)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip', style: TextStyle(color: Color(0xFF7E7E7E))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable', style: TextStyle(color: Color(0xFFF7CD57))),
            ),
          ],
        ),
      );

      if (enable == true && mounted) {
        final token = LocalStorageService.getToken() ?? '';
        final profile = LocalStorageService.getUserProfile() ?? {};
        await biometric.saveLoginResult(token, profile);
        await biometric.enable();
      }
    } catch (_) {}
  }

  Future<void> _createAugmontUser() async {
    final pending = LocalStorageService.getPendingRegistrationProfile();
    if (pending == null) return;
    try {
      final mobileNum = pending['mobileNumber']?.toString() ?? widget.mobileNumber;
      final dob = pending['dateOfBirth']?.toString() ?? widget.dateOfBirth;
      final joinedDob = dob.replaceAll(RegExp(r'[^\d]'), '');
      final uniqueId = '$mobileNum$joinedDob';

      final api = AugmontApi(ref.read(augmontDioProvider));
      await api.createAugmontUser({
        'merchantId': '11692',
        'mobileNumber': mobileNum,
        'emailId': pending['email']?.toString() ?? widget.email,
        'uniqueId': uniqueId,
        'userName': pending['fullName']?.toString() ?? widget.fullName,
        'stateName': pending['stateName']?.toString() ?? '',
        'cityName': pending['cityName']?.toString() ?? '',
        'userPincode': pending['pinCode']?.toString() ?? '',
      });
      await LocalStorageService.setPendingRegistrationProfile(null);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.97, -1.0),
                radius: 1.25,
                colors: [Color(0xFF4A3A1E), Color(0xFF000000)],
                stops: [0.0, 0.9945],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
              children: [
                const SizedBox(height: 16),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.8),
                      ),
                      child: const Icon(Icons.chevron_left, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Logo
                const AnimatedRingLogo(),
                const SizedBox(height: 16),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7D5800)),
                    color: const Color(0xFF161000),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      const SizedBox(width: 10),
                      const Text(
                        'ONE TIME PASSWORD',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Step indicator
                const Text(
                  'ALMOST THERE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF999999), letterSpacing: 3),
                ),
                const SizedBox(height: 12),
                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'Unlock your ',
                    style: TextStyle(fontFamily: 'Playfair Display', fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                    children: [
                      TextSpan(
                        text: 'Gold',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFFD9A639)),
                      ),
                      TextSpan(text: '\nVault'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Gold divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 39, height: 1, color: const Color(0xFF6A511C)),
                    const SizedBox(width: 12),
                    Transform.rotate(angle: 0.7854, child: Container(width: 8, height: 8, color: const Color(0xFFB57F23))),
                    const SizedBox(width: 12),
                    Container(width: 39, height: 1, color: const Color(0xFF6A511C)),
                  ],
                ),
                const SizedBox(height: 16),
                // Subtitle
                Text.rich(
                  TextSpan(
                    text: 'A 4-digit secure code was sent to\n',
                    style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFFFF6D9)),
                    children: [
                      TextSpan(
                        text: _maskedPhone,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
                  ),
                ],
                const SizedBox(height: 24),
                // OTP inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 64,
                      height: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFFFFF6D9)),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _controllers[index].text.isNotEmpty ? Colors.black : const Color(0xFF1B1611),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _controllers[index].text.isNotEmpty ? const Color(0xFFF7CD57) : const Color(0xFF3C351F),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _controllers[index].text.isNotEmpty ? const Color(0xFFF7CD57) : const Color(0xFF3C351F),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Color(0xFFF7CD57), width: 2),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.isNotEmpty && index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_controllers.every((c) => c.text.isNotEmpty)) {
                            _verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive code? ",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9C9C9B)),
                    ),
                    GestureDetector(
                      onTap: _isResending ? null : _resendOtp,
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFE8B438)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Verify button
                GestureDetector(
                  onTap: _isVerifying ? null : _verifyOtp,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isVerifying ? 'Verifying...' : 'Verify & Continue',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                        if (!_isVerifying) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 20, color: Colors.black),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Change details
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Change email or mobile',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF7C7B79)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      _buildKycOverlay(),
    ],
  ),
);
  }

  Widget _buildKycOverlay() {
    if (!_showKycPrompt) return const SizedBox.shrink();
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.7)),
        Center(
            child: Container(
            width: 358, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0x4DF7CD57)),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF503B15), Color(0xFF1C1408), Color(0xFF080603)])),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(clipBehavior: Clip.none, children: [
                Positioned(right: -48, top: -64,
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(width: 144, height: 144,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: const Color(0xFFF7CD57).withOpacity(0.15))))),
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(colors: [Color(0xFFFFE784), Color(0xFFC88912)])),
                  child: const Icon(Icons.shield, color: Color(0xFF11130F), size: 25)),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF7CD57))),
                const SizedBox(width: 6),
                const Text('KYC UNLOCKS HIGHER LIMITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: Color(0xFFF7CD57))),
              ]),
              const SizedBox(height: 8),
              const Text('Purchase limit reached', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Your purchase limit is ₹1,000. Complete KYC to buy more.', style: TextStyle(fontSize: 12, color: Color(0xFFD5C7A8)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.replace('/kyc-verification'),
                child: Container(width: double.infinity, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)])),
                  child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Complete KYC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                  ]))),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.replace('/home'),
                child: const Text('I will do it later', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
