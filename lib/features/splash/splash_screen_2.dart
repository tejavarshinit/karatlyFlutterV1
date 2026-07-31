import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen2 extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback onNext;
  const SplashScreen2({super.key, required this.onSkip, required this.onNext});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _textController;
  late final AnimationController _logoController;
  late final AnimationController _bottomBarController;
  late final AnimationController _featureGridController;
  late final AnimationController _ctaController;
  late final AnimationController _shimmerController;
  late final AnimationController _dividerController;

  static const _features = [
    _FeatureData(icon: Icons.lock, label: '100% secure\nvault storage'),
    _FeatureData(icon: Icons.shopping_cart, label: 'Instant Buy &\nSell / Redeem'),
    _FeatureData(icon: Icons.trending_up, label: 'Live Market\nRates'),
    _FeatureData(icon: Icons.local_shipping, label: 'Physical Delivery\nAvailable'),
    _FeatureData(icon: Icons.sell, label: 'Transparent\nPricing'),
    _FeatureData(icon: Icons.headset_mic, label: 'Dedicated\nCustomer Support'),
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bottomBarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _featureGridController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _dividerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));

    _startAnimations();
  }

  void _startAnimations() async {
    // Skip button fades in at 0.5s
    // Hero image: starts at 0.3s
    await Future.delayed(const Duration(milliseconds: 300));
    _heroController.forward();

    // Text: starts at 1.2s
    await Future.delayed(const Duration(milliseconds: 900));
    _textController.forward();

    // Logo: starts at 1.4s
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Bottom bar: slides up at 1.6s
    await Future.delayed(const Duration(milliseconds: 200));
    _bottomBarController.forward();
    _dividerController.repeat();

    // Feature grid: starts at 2.0s
    await Future.delayed(const Duration(milliseconds: 400));
    _featureGridController.forward();

    // CTA: starts at 3.0s
    await Future.delayed(const Duration(milliseconds: 1000));
    _ctaController.forward();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _textController.dispose();
    _logoController.dispose();
    _bottomBarController.dispose();
    _featureGridController.dispose();
    _ctaController.dispose();
    _shimmerController.dispose();
    _dividerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0E),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFAA00).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 28,
            right: 24,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _heroController,
                curve: const Interval(0.0, 0.5),
              ),
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

          // Main content - centered with max width
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 60),

              // Hero image
              Expanded(
                flex: 3,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _heroController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.05, end: 1.0).animate(
                      CurvedAnimation(parent: _heroController, curve: const Interval(0.3, 1.0)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/splash2_hero.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Bottom gradient fade
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF080A0E).withValues(alpha: 0.4),
                                  const Color(0xFF080A0E),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Text section
              FadeTransition(
                opacity: _textController,
                child: Column(
                  children: [
                    Text(
                      "India's most trusted digital gold platform",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFFFD700),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start with as little as ₹10',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _logoController,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(_logoController),
                        child: Image.asset(
                          'assets/images/splash_logo.png',
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom feature bar
              SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
                  CurvedAnimation(
                    parent: _bottomBarController,
                    curve: const Cubic(0.22, 1.0, 0.36, 1),
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0C10),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(color: Color(0x26FFB900), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 50,
                        offset: Offset(0, -20),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      // Scrolling dashed divider
                      SizedBox(
                        height: 2,
                        child: AnimatedBuilder(
                          animation: _dividerController,
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(-120 + _dividerController.value * 120, 0),
                              child: Row(
                                children: List.generate(40, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 4, height: 2, color: const Color(0x80FFB900)),
                                        const SizedBox(width: 2),
                                        Container(width: 20, height: 2, color: const Color(0x2EFFB900)),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Feature icons grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _features.length,
                        itemBuilder: (context, i) {
                          final feature = _features[i];
                          final delay = 2.0 + i * 0.15;
                          return AnimatedBuilder(
                            animation: _featureGridController,
                            builder: (context, _) {
                              final t = ((_featureGridController.value - delay / 3.2).clamp(0.0, 1.0));
                              final scale = 0.5 + (t * 0.5);
                              final opacity = t;
                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0x4DFFB900)),
                                          color: const Color(0x14FFB900),
                                        ),
                                        child: Icon(feature.icon, size: 18, color: const Color(0xFFFFB800)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        feature.label,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFA07830),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // CTA Button
                      FadeTransition(
                        opacity: _ctaController,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.88, end: 1.0).animate(_ctaController),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: widget.onNext,
                                child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
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
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Text(
                                        "Get Started — It's Free",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF080A0E),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      // Shimmer
                                      AnimatedBuilder(
                                        animation: _shimmerController,
                                        builder: (context, _) {
                                          return Positioned.fill(
                                            child: FractionallySizedBox(
                                              widthFactor: 0.3,
                                              child: Transform.translate(
                                                offset: Offset(
                                                  -40 + _shimmerController.value * 200,
                                                  0,
                                                ),
                                            child: Transform(
                                              transform: Matrix4.skewX(-0.44),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.white.withValues(alpha: 0.4),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hidden charges · RBI compliant · 24/7 support',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A2A10),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
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
   ],
 ),
);
  }
}

class _FeatureData {
  final IconData icon;
  final String label;
  const _FeatureData({required this.icon, required this.label});
}
