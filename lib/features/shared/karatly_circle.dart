import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Reusable KARATLY branded circle component.
class KaratlyCircle extends StatelessWidget {
  final double size;
  final String? metalType;
  final bool showBorder;

  const KaratlyCircle({
    super.key,
    this.size = 60,
    this.metalType,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSilver = metalType == 'silver';
    final isDiamond = metalType == 'diamond';

    final outerGradient = isSilver
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8EEF5), Color(0xFF8E9AAA)],
          )
        : isDiamond
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0073CE), Color(0xFF003A68)],
              )
            : const RadialGradient(
                center: Alignment(-0.15, -0.2),
                radius: 1.2,
                colors: [Color(0xFFFFE27A), Color(0xFFF5BF31), Color(0xFFC98900)],
              );

    final innerGradient = isSilver
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0E0E0), Color(0xFF7A7A7A)],
          )
        : isDiamond
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0073CE), Color(0xFF003A68)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8D862), Color(0xFFD59B12)],
              );

    final borderColor = isSilver
        ? Colors.white.withOpacity(0.25)
        : isDiamond
            ? const Color(0xFF0073CE).withOpacity(0.25)
            : const Color(0xFFE8B438).withOpacity(0.25);

    final textColor = isSilver
        ? const Color(0xFFE8EEF5)
        : isDiamond
            ? const Color(0xFF4593F9)
            : const Color(0xFFC89111);

    final innerSize = size * 0.867;
    final fontSize = size * 0.167;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: outerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: innerGradient,
            border: showBorder
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              'KARATLY',
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
