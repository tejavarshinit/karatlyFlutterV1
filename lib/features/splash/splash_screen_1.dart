import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen1 extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback onNext;
  const SplashScreen1({super.key, required this.onSkip, required this.onNext});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> with TickerProviderStateMixin {
  late final AnimationController _jarController;
  late final AnimationController _coinRainController;
  late final AnimationController _liquidController;
  late final AnimationController _overflowController;
  late final AnimationController _textController;
  late final AnimationController _ctaController;
  late final AnimationController _logoController;
  late final AnimationController _shimmerController;

  final List<_CoinData> _coins = [];
  final List<_CoinData> _overflowCoins = [];
  bool _showOverflow = false;

  @override
  void initState() {
    super.initState();
    _jarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _coinRainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _liquidController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _overflowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ctaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    final rng = math.Random();
    for (int i = 0; i < 20; i++) {
      _coins.add(_CoinData(
        isGold: rng.nextDouble() > 0.4,
        delay: rng.nextDouble() * 0.9,
        duration: 0.28 + rng.nextDouble() * 0.24,
        startX: (rng.nextDouble() - 0.5) * 80,
        rotation: (rng.nextDouble() - 0.5) * 60,
        scale: 0.5 + rng.nextDouble() * 0.2,
        drift: (rng.nextDouble() - 0.5) * 16,
      ));
    }
    for (int i = 0; i < 8; i++) {
      _overflowCoins.add(_CoinData(
        isGold: rng.nextDouble() > 0.5,
        side: rng.nextDouble() > 0.5 ? 1 : -1,
        delay: i * 0.1,
        rotation: (rng.nextDouble() - 0.5) * 360,
        overflow: true,
      ));
    }

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    _jarController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _coinRainController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _liquidController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _showOverflow = true);
    _overflowController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    _ctaController.forward();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _jarController.dispose();
    _coinRainController.dispose();
    _liquidController.dispose();
    _overflowController.dispose();
    _textController.dispose();
    _ctaController.dispose();
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Karatly Logo - top center
          Positioned(
            top: MediaQuery.of(context).padding.top + 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _logoController,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
                  CurvedAnimation(parent: _logoController, curve: const Cubic(0.34, 1.56, 0.64, 1)),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Skip button - top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 28,
            right: 24,
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _logoController, curve: const Interval(0.5, 1.0)),
              child: GestureDetector(
                onTap: widget.onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
                  ),
                ),
              ),
            ),
          ),

          // Main centered content
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Jar + Coins container
                      SizedBox(
                        width: 360,
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Jar image
                            AnimatedBuilder(
                              animation: _jarController,
                              builder: (context, _) {
                                final t = _jarController.value;
                                final scale = 0.85 + (t * 0.05);
                                final y = t * 10;
                                final opacity = t.clamp(0.0, 1.0);
                                return Transform.translate(
                                  offset: Offset(0, y),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: SizedBox(
                                        width: 280,
                                        height: 280,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Liquid fill
                                            Positioned(
                                              bottom: 56,
                                              child: AnimatedBuilder(
                                                animation: _liquidController,
                                                builder: (context, _) {
                                                  final liquidHeight = _liquidController.value * 0.65;
                                                  return ClipRRect(
                                                    borderRadius: const BorderRadius.only(
                                                      bottomLeft: Radius.circular(45),
                                                      bottomRight: Radius.circular(45),
                                                    ),
                                                    child: Container(
                                                      width: 280 * 0.66,
                                                      height: 280 * liquidHeight,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            const Color(0xFFFFC300).withValues(alpha: 0.35),
                                                            const Color(0xFFFFC300).withValues(alpha: 0.2),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // Jar image on top
                                            Image.asset(
                                              'assets/images/splash_jar.png',
                                              width: 280,
                                              height: 280,
                                              fit: BoxFit.contain,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Coin rain
                            ...List.generate(_coins.length, (i) {
                              final coin = _coins[i];
                              final anim = _coinRainController;
                              return AnimatedBuilder(
                                animation: anim,
                                builder: (context, _) {
                                  final progress = anim.value;
                                  final coinProgress = ((progress - coin.delay / 1.2).clamp(0.0, 1.0)) /
                                      (1.0 - coin.delay / 1.2).clamp(0.01, 1.0);
                                  final t = coinProgress.clamp(0.0, 1.0);

                                  double opacity;
                                  if (t < 0.2) {
                                    opacity = t / 0.2;
                                  } else if (t > 0.8) {
                                    opacity = (1.0 - t) / 0.2;
                                  } else {
                                    opacity = 1.0;
                                  }

                                  final y = -120.0 + t * 150.0;
                                  final x = coin.startX + (t * coin.drift * 0.5);
                                  final rotation = t * coin.rotation;

                                  return Transform.translate(
                                    offset: Offset(x, y),
                                    child: Transform.rotate(
                                      angle: rotation * math.pi / 180,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Image.asset(
                                          coin.isGold ? 'assets/images/goldcoin.png' : 'assets/images/silvercoin.png',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),

                            // Overflow coins
                            if (_showOverflow)
                              ...List.generate(_overflowCoins.length, (i) {
                                final coin = _overflowCoins[i];
                                return AnimatedBuilder(
                                  animation: _overflowController,
                                  builder: (context, _) {
                                    final t = (_overflowController.value - coin.delay).clamp(0.0, 1.0);
                                    final opacity = (1.0 - t).clamp(0.0, 1.0);
                                    final y = t * 110.0;
                                    final x = coin.side * (40.0 + t * 60.0);
                                    final rotation = t * coin.rotation * 2;

                                    return Transform.translate(
                                      offset: Offset(x, y),
                                      child: Transform.rotate(
                                        angle: rotation * math.pi / 180,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: Image.asset(
                                            coin.isGold ? 'assets/images/goldcoin.png' : 'assets/images/silvercoin.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Text block
                      FadeTransition(
                        opacity: _textController,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_textController),
                          child: Column(
                            children: [
                              const Text(
                                'Simplifying Finance for Everyone',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Buy, Sell & Redeem Gold, Silver, and Diamonds with confidence.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFD4AF6A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Smart investing made simple, secure, and accessible.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFFA89060)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA Button
                      FadeTransition(
                        opacity: _ctaController,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.0).animate(_ctaController),
                          child: GestureDetector(
                            onTap: widget.onNext,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Start Your Wealth Journey',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF1A1A1A)),
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
        ],
      ),
    );
  }
}

class _CoinData {
  final bool isGold;
  final double delay;
  final double duration;
  final double startX;
  final double rotation;
  final double scale;
  final double drift;
  final int side;
  final bool overflow;

  const _CoinData({
    required this.isGold,
    this.delay = 0,
    this.duration = 0,
    this.startX = 0,
    this.rotation = 0,
    this.scale = 1,
    this.drift = 0,
    this.side = 1,
    this.overflow = false,
  });
}
