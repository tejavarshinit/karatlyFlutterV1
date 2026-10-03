import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/services/auth_provider.dart';
import 'widgets/animated_ring_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizeMobile(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('0091')) {
      digits = digits.substring(4);
    }
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<void> _sendOtp() async {
    if (!_acceptedTerms) {
      setState(() => _error =
          'Please agree to the Terms and Conditions before continuing.');
      return;
    }

    final normalizedMobile = _normalizeMobile(_phoneController.text);
    if (normalizedMobile.length != 10) {
      setState(() =>
          _error = 'Invalid mobile number format. Must be exactly 10 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).sendOtp(
            mobileNumber: normalizedMobile,
            type: 'login',
          );
      if (mounted) {
        final success = result['ok'] == true || result['success'] == true;
        final notRegistered = result['notRegistered'] == true;
        if (success && !notRegistered) {
          GoRouter.of(context).push(AppRoutes.otp, extra: {
            'mobileNumber': normalizedMobile,
            'type': 'login',
          });
        } else if (notRegistered) {
          setState(() => _error =
              'This mobile number is not registered. Please create an account first.');
        } else {
          setState(() =>
              _error = result['message']?.toString() ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Unable to send OTP. Please check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.97, -1.0),
            radius: 1.25,
            colors: [
              Color(0xFF4A3A1E),
              Color(0xFF000000),
            ],
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
                    onTap: () => context.go(AppRoutes.signup),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.8),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Logo
                const AnimatedRingLogo(),
                const SizedBox(height: 16),
                // Vault Access badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7D5800)),
                    color: const Color(0xFF161000),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        'VAULT ACCESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Step indicator
                const Text(
                  'STEP 1 OF 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF999999),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'Welcome back to ',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: 'Karatly',
                        style: TextStyle(color: Color(0xFFD9A639)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Gold divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 39, height: 1, color: const Color(0xFFC7C7C7)),
                    const SizedBox(width: 12),
                    Transform.rotate(
                      angle: 0.7854,
                      child: Container(
                        width: 8,
                        height: 8,
                        color: const Color(0xFFB57F23),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                        width: 39, height: 1, color: const Color(0xFFC7C7C7)),
                  ],
                ),
                const SizedBox(height: 12),
                // Subtitle
                const Text(
                  'Sign in with your registered mobile number to continue your precious-metals journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFFFFF6D9),
                  ),
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
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.redAccent),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Mobile input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: (v) {
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (v != digits) {
                      _phoneController.text = digits;
                      _phoneController.selection = TextSelection.fromPosition(
                        TextPosition(offset: digits.length),
                      );
                    }
                  },
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFFF6D9),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mobile number *',
                    counterText: '',
                    hintStyle: const TextStyle(color: Color(0xFF5E5B5B)),
                    filled: true,
                    fillColor: const Color(0xFF1A1510),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF666666)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF666666)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF666666)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),
                const SizedBox(height: 16),
                // Terms checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _acceptedTerms = !_acceptedTerms),
                      child: Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _acceptedTerms
                                ? const Color(0xFFE8B438)
                                : const Color(0xFF666666),
                          ),
                          color: _acceptedTerms
                              ? const Color(0xFFE8B438)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: _acceptedTerms
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.black)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(children: [
                        Text("By continuing, you agree to our ",
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color:
                                    const Color(0xFFBDB6A0).withOpacity(0.9))),
                        GestureDetector(
                          onTap: () => context.push('/terms'),
                          child: const Text('Terms',
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Color(0xFFF7CD57),
                                  decoration: TextDecoration.underline)),
                        ),
                        Text(" & ",
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color:
                                    const Color(0xFFBDB6A0).withOpacity(0.9))),
                        GestureDetector(
                          onTap: () => context.push('/privacy-policy'),
                          child: const Text('Privacy Policy',
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Color(0xFFF7CD57),
                                  decoration: TextDecoration.underline)),
                        ),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Send OTP button
                GestureDetector(
                  onTap: _isLoading ? null : _sendOtp,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF7CD57),
                          Color(0xFFE5AF35),
                          Color(0xFFB57F23),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoading ? 'Sending...' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        if (!_isLoading) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward,
                              size: 20, color: Colors.black),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Secure login divider
                Row(
                  children: [
                    Expanded(
                        child: Container(
                            height: 1, color: const Color(0xFFC1C1C1))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'SECURE LOGIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFBABAB7),
                        ),
                      ),
                    ),
                    Expanded(
                        child: Container(
                            height: 1, color: const Color(0xFFC1C1C1))),
                  ],
                ),
                const SizedBox(height: 12),
                // Security info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 12, color: Color(0xFFE8B438)),
                    const SizedBox(width: 8),
                    const Text(
                      '256-bit encrypted - BIS verified platform',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF9C9C9B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Create account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New to Karatly? ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFF6D9),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.signup),
                      child: const Text(
                        'create account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE8B438),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
