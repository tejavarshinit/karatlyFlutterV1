import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen3 extends StatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onLogin;
  const SplashScreen3({super.key, required this.onSignUp, required this.onLogin});

  @override
  State<SplashScreen3> createState() => _SplashScreen3State();
}

class _SplashScreen3State extends State<SplashScreen3> with TickerProviderStateMixin {
  late final AnimationController _coinController;
  late final AnimationController _tagController;
  late final AnimationController _badgeController;
  late final AnimationController _headlineController;
  late final AnimationController _bodyController;
  late final AnimationController _cta1Controller;
  late final AnimationController _cta2Controller;
  late final AnimationController _bobController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _tagController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _badgeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headlineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bodyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cta1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cta2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bobController = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000));
    _rotateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000));

    _startAnimations();
  }

  void _startAnimations() async {
    // Coin entrance: from x=-40, y=20, delay 0.1s (splash4 spring: very slow bouncy)
    await Future.delayed(const Duration(milliseconds: 100));
    _coinController.forward();
    _bobController.repeat(reverse: true);
    _rotateController.repeat(reverse: true);

    // Tag chip: from x=-60, delay 0.2s (splash3 spring)
    await Future.delayed(const Duration(milliseconds: 100));
    _tagController.forward();

    // Badge: y=-50 entrance, delay 0.35s (successBounce spring)
    await Future.delayed(const Duration(milliseconds: 150));
    _badgeController.forward();

    // Headline: from x=-40, delay 0.5s (splash3 spring)
    await Future.delayed(const Duration(milliseconds: 150));
    _headlineController.forward();

    // Body: from x=-40, delay 0.6s
    await Future.delayed(const Duration(milliseconds: 100));
    _bodyController.forward();

    // CTA buttons: from x=60, delay 0.8s and 0.9s (splash5 spring)
    await Future.delayed(const Duration(milliseconds: 200));
    _cta1Controller.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _cta2Controller.forward();
  }

  @override
  void dispose() {
    _coinController.dispose();
    _tagController.dispose();
    _badgeController.dispose();
    _headlineController.dispose();
    _bodyController.dispose();
    _cta1Controller.dispose();
    _cta2Controller.dispose();
    _bobController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Radial gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.975, 0.379),
                  radius: 1.04,
                  colors: [
                    Color(0x524A3A1E),
                    Color(0x1E4A3A1E),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.24, 0.62],
                ),
              ),
            ),
          ),

          // Floating cinematic coin - centered with max width
          Positioned(
            top: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: AnimatedBuilder(
                  animation: _coinController,
                  builder: (context, _) {
                    final enterT = CurvedAnimation(
                      parent: _coinController,
                      curve: const Cubic(0.34, 1.56, 0.64, 1),
                    );
                    return Transform.translate(
                      offset: Offset(-40 * (1 - enterT.value), 20 * (1 - enterT.value)),
                      child: Opacity(
                        opacity: enterT.value.clamp(0.0, 1.0),
                        child: AnimatedBuilder(
                          animation: _bobController,
                          builder: (context, _) {
                            final bob = math.sin(_bobController.value * math.pi) * 8;
                            return AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, _) {
                                final rot = math.sin(_rotateController.value * math.pi * 0.5) * 6;
                                return Transform.translate(
                                  offset: Offset(0, bob),
                                  child: Transform.rotate(
                                    angle: rot * math.pi / 180,
                                    child: Image.asset(
                                      'assets/images/splash_logo.png',
                                      width: 224,
                                      height: 224,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Bottom content - centered with max width
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  // Tag chip: "Final Step"
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _tagController,
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _tagController,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE8B438)),
                            color: const Color(0xF22D2517),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Final Step',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFF6D9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Trusted By badge
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _badgeController,
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _badgeController,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x66E8B438)),
                            color: const Color(0xEC2D2517),
                          ),
                          child: const Text(
                            '★ Trusted By 50k+ Investors',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFF6D9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Headline: "Start Your Golden Journey"
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(-0.35, 0), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _headlineController,
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _headlineController,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Start Your ',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Playfair Display',
                                height: 1.15,
                              ),
                            ),
                            TextSpan(
                              text: 'Golden Journey',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Playfair Display',
                                height: 1.15,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)],
                                  ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Body text
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(-0.35, 0), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _bodyController,
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _bodyController,
                      child: const Text(
                        'Create your account and begin with a premium investing flow designed for confidence, clarity and growth.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFAFFF6D9),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CTA: Create Account
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _cta1Controller,
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _cta1Controller,
                      child: GestureDetector(
                        onTap: widget.onSignUp,
                        child: Container(
                          width: 342,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE5AF35).withValues(alpha: 0.55),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward, size: 20, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CTA: Login (outline)
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _cta2Controller,
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _cta2Controller,
                      child: GestureDetector(
                        onTap: widget.onLogin,
                        child: Container(
                          width: 342,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFCB952B)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFF6D9),
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward, size: 20, color: Color(0xFFFFF6D9)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

          // Pagination dots (4th active)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final active = i == 3;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 40 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: active
                        ? const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)])
                        : null,
                    color: active ? null : const Color(0xFF333333),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
