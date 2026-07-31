import 'dart:async';
import 'package:flutter/material.dart';

const _ringFrames = [
  'assets/images/frame_2.png',
  'assets/images/frame_3.png',
  'assets/images/frame_4.png',
  'assets/images/frame_5.png',
];

class AnimatedRingLogo extends StatefulWidget {
  final double size;

  const AnimatedRingLogo({super.key, this.size = 110});

  @override
  State<AnimatedRingLogo> createState() => _AnimatedRingLogoState();
}

class _AnimatedRingLogoState extends State<AnimatedRingLogo> {
  int _frameIdx = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      setState(() => _frameIdx = (_frameIdx + 1) % _ringFrames.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final innerSize = size * 0.8;
    final innerOffset = size * 0.1;
    final logoSize = size * 0.65;
    final logoOffset = (size - logoSize) / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _ringFrames[_frameIdx],
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: innerOffset,
            top: innerOffset,
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              child: Center(
                child: Image.asset(
                  'assets/images/KaratlyLOGO-removebg-preview.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
