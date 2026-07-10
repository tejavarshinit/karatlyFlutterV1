import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'karatly_circle.dart';

/// Rate/holdings card matching reference pattern with gradient border and KARATLY circle.
class RateCard extends StatelessWidget {
  final String label;
  final String rateText;
  final String subtitle;
  final String metalType;
  final bool showLiveIndicator;

  const RateCard({
    super.key,
    required this.label,
    required this.rateText,
    required this.subtitle,
    this.metalType = 'gold',
    this.showLiveIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSilver = metalType == 'silver';
    final isDiamond = metalType == 'diamond';

    final borderColor = isSilver
        ? Colors.white
        : isDiamond
            ? const Color(0xFF0073CE)
            : const Color(0xFFE8B438);

    final cardBg = isSilver
        ? const LinearGradient(
            begin: Alignment(2.45, 0.38),
            end: Alignment(-0.45, 0.55),
            colors: [Color(0xFF495C73), Color(0xFF0D1117)],
          )
        : isDiamond
            ? const LinearGradient(
                begin: Alignment(2.45, 0.38),
                end: Alignment(-0.45, 0.55),
                colors: [Color(0xFF05438B), Color(0xFF0D1117)],
              )
            : const LinearGradient(
                begin: Alignment(2.45, 0.38),
                end: Alignment(-0.45, 0.55),
                colors: [Color(0xFF6C5123), Color(0xFF1E2A28)],
              );

    final rateColor = isSilver || isDiamond
        ? Colors.white
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        gradient: cardBg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    color: Color(0xFFA1A1A1),
                  ),
                ),
                const SizedBox(height: 4),
                rateColor != null
                    ? Text(
                        rateText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 36 / 24,
                          color: rateColor,
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                        ).createShader(bounds),
                        child: Text(
                          rateText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 36 / 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                if (showLiveIndicator) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 12, color: Color(0xFF0EA300)),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 15 / 10,
                          color: Color(0xFF0EA300),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          KaratlyCircle(size: 60, metalType: metalType),
        ],
      ),
    );
  }
}

/// Compact rate card for payment/review steps
class RateCardCompact extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final String metalType;

  const RateCardCompact({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    this.metalType = 'gold',
  });

  @override
  Widget build(BuildContext context) {
    final isSilver = metalType == 'silver';
    final isDiamond = metalType == 'diamond';

    final borderColor = isSilver
        ? const Color(0xFF495C73)
        : isDiamond
            ? const Color(0xFF05438B)
            : const Color(0xFF3E3522);

    final bgColor = isSilver
        ? const Color(0xFF1C2633)
        : isDiamond
            ? const Color(0xFF0D1F3D)
            : const Color(0xFF201B0F);

    final valueColor = isSilver || isDiamond
        ? Colors.white
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7E7E7E),
                  ),
                ),
                const SizedBox(height: 4),
                valueColor != null
                    ? Text(
                        value,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFF8CF59), Color(0xFFF7CD57)],
                        ).createShader(bounds),
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFF1A301E),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15EE01),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
