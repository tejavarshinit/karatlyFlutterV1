import 'package:flutter/material.dart';

class SuccessAnimation extends StatefulWidget {
  final String? text;

  const SuccessAnimation({super.key, this.text});

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
    _particleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(6, (i) {
                return AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    final progress = _particleController.value;
                    final distance = progress * 80;
                    final opacity = (1 - progress).clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(
                        distance * (i % 2 == 0 ? 1 : -1) * 0.7,
                        -distance * (i < 3 ? 1 : -1) * 0.7,
                      ),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7CD57),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF7CD57).withOpacity(0.2),
                  ),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF7CD57),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF7CD57).withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: Colors.black,
                        weight: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.text != null) ...[
          const SizedBox(height: 24),
          Text(
            widget.text!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
