import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Flow overlay wrapper that provides the consistent dark gradient background
/// with rounded top corners, matching the reference PopupModal pattern.
///
/// This is a simple wrapper - each flow step uses this as its root widget
/// to maintain visual consistency across all buy/sell/SIP flows.
class FlowOverlay extends StatelessWidget {
  final Widget child;
  final String metalType;
  final double minHeight;

  const FlowOverlay({
    super.key,
    required this.child,
    this.metalType = 'gold',
    this.minHeight = 86,
  });

  Color _getGradientStart() {
    switch (metalType) {
      case 'silver':
        return const Color(0xFF293341);
      case 'diamond':
        return const Color(0xFF293341);
      default:
        return const Color(0xFF4A3A1E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * minHeight / 100,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
        gradient: RadialGradient(
          center: const Alignment(0.94, -0.95),
          radius: 1.2,
          colors: [_getGradientStart(), Colors.black],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 60,
            offset: Offset(0, -24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
        child: Stack(
          children: [
            // Inner gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.02),
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.35),
                    ],
                    stops: const [0, 0.18, 1],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
