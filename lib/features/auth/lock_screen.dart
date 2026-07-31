import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';
import 'widgets/animated_ring_logo.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _biometric = BiometricAuthService();
  bool _checking = true;
  bool _authenticating = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final enabled = await _biometric.isEnabled();
    if (!mounted) return;

    if (!enabled) {
      context.go(AppRoutes.splash);
      return;
    }

    setState(() {
      _checking = false;
      _message = 'Tap to unlock';
    });
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _message = 'Verifying...';
    });

    try {
      final userInfo = await _biometric.login();
      if (!mounted) return;

      if (userInfo != null) {
        final jwt = await _biometric.getStoredJwt();
        if (jwt != null && jwt.isNotEmpty) {
          await LocalStorageService.setToken(jwt);
          ref.read(authProvider.notifier).restoreFromToken(jwt);
          context.go(AppRoutes.home);
          return;
        }
      }

      setState(() {
        _authenticating = false;
        _message = 'Failed to unlock. Use password.';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go(AppRoutes.splash);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authenticating = false;
        _message = 'Something went wrong';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go(AppRoutes.splash);
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
            colors: [Color(0xFF4A3A1E), Color(0xFF000000)],
            stops: [0.0, 0.9945],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedRingLogo(),
                const SizedBox(height: 24),
                const Text(
                  'Karatly',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _message,
                  style: const TextStyle(color: Color(0xFF9E9A94), fontSize: 14),
                ),
                if (_checking) ...[
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF7CD57)),
                  ),
                ],
                if (!_checking && !_authenticating) ...[
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _authenticate,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF7CD57), width: 2),
                        color: const Color(0xFF1A1918),
                      ),
                      child: const Icon(Icons.fingerprint, size: 32, color: Color(0xFFF7CD57)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.splash),
                    child: const Text(
                      'Use password instead',
                      style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
