import 'dart:ui';
import 'package:flutter/material.dart';

class GlowBackdrop extends StatelessWidget {
  final Widget child;
  final List<GlowConfig> glows;
  final Clip clipBehavior;

  const GlowBackdrop({
    super.key,
    required this.child,
    required this.glows,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: clipBehavior,
      children: [
        ...glows.map((g) => Positioned(
          left: g.left,
          top: g.top,
          right: g.right,
          bottom: g.bottom,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: g.blurSigma, sigmaY: g.blurSigma),
            child: Container(
              width: g.size,
              height: g.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: g.color.withOpacity(g.opacity),
              ),
            ),
          ),
        )),
        child,
      ],
    );
  }
}

class GlowConfig {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;
  final double blurSigma;

  const GlowConfig({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  });
}
