import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/services/home_provider.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: _FloatingNavBar()),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends ConsumerWidget {
  const _FloatingNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final metal = ref.watch(activeMetalProvider);
    final accent = metal == 'diamond'
        ? const Color(0xFF3AC7FF)
        : metal == 'silver'
            ? Colors.white
            : const Color(0xFFF7CD57);
    return Container(
      width: 342,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF242320),
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 30,
            spreadRadius: 20,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: 'home',
            label: 'Home',
            isActive: currentPath == AppRoutes.home,
            accent: accent,
            onTap: () => context.go(AppRoutes.home),
          ),
          _NavItem(
            icon: 'dashboard',
            label: 'Dashboard',
            isActive: currentPath == AppRoutes.dashboard,
            accent: accent,
            onTap: () => context.go(AppRoutes.dashboard),
          ),
          _NavItem(
            icon: 'market',
            label: 'Market',
            isActive: currentPath == AppRoutes.market,
            accent: accent,
            onTap: () => context.go(AppRoutes.market),
          ),
          _NavItem(
            icon: 'orders',
            label: 'Order',
            isActive: currentPath == AppRoutes.orders,
            accent: accent,
            onTap: () => context.go(AppRoutes.orders),
          ),
          _NavItem(
            icon: 'profile',
            label: 'Profile',
            isActive: currentPath == AppRoutes.profile,
            accent: accent,
            onTap: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? accent : const Color(0xFF707070);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavIcon(type: icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String type;
  final Color color;

  const _NavIcon({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(painter: _NavIconPainter(type: type, color: color)),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  final String type;
  final Color color;

  _NavIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (type) {
      case 'home':
        final path = Path()
          ..moveTo(w * 0.1875, h * 0.3906)
          ..lineTo(w * 0.5, h * 0.125)
          ..lineTo(w * 0.8125, h * 0.3906)
          ..lineTo(w * 0.8125, h * 0.8281)
          ..lineTo(w * 0.6094, h * 0.8281)
          ..lineTo(w * 0.6094, h * 0.5625)
          ..lineTo(w * 0.3906, h * 0.5625)
          ..lineTo(w * 0.3906, h * 0.8281)
          ..lineTo(w * 0.1875, h * 0.8281)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case 'dashboard':
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5, 1.5, 5, 5), const Radius.circular(1.2));
        canvas.drawRRect(r, fillPaint);
        final r2 = RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5, 9.5, 5, 5), const Radius.circular(1.2));
        canvas.drawRRect(r2, fillPaint);
        final r3 = RRect.fromRectAndRadius(
          Rect.fromLTWH(9.5, 1.5, 5, 5), const Radius.circular(1.2));
        canvas.drawRRect(r3, fillPaint);
        final checkPath = Path()
          ..moveTo(9.6, 11.7)
          ..lineTo(11.2, 13.3)
          ..lineTo(14, 10.5);
        canvas.drawPath(checkPath, paint..strokeWidth = 1.2);
        break;

      case 'market':
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(2, 9.5, 2, 4.5), const Radius.circular(1)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(6.5, 6.5, 2, 7.5), const Radius.circular(1)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(11, 3.5, 2, 10.5), const Radius.circular(1)),
          fillPaint,
        );
        canvas.drawPath(
          Path()..moveTo(1.5, 13.5)..lineTo(14.5, 13.5),
          paint,
        );
        break;

      case 'orders':
        canvas.drawPath(
          Path()..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(3.5, 2.5, 8, 11), const Radius.circular(1.2))),
          paint,
        );
        canvas.drawLine(Offset(6, 5.5), Offset(9.5, 5.5), paint);
        canvas.drawLine(Offset(6, 8), Offset(9.5, 8), paint);
        canvas.drawLine(Offset(5.5, 12.2), Offset(10.5, 12.2), paint);
        break;

      case 'profile':
        final circle = Path()..addOval(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.3125), radius: 2.5));
        canvas.drawPath(circle, paint);
        final bodyPath = Path()
          ..moveTo(w * 0.2188, h * 0.8125)
          ..quadraticBezierTo(w * 0.275, h * 0.6813, w * 0.5, h * 0.6094)
          ..quadraticBezierTo(w * 0.725, h * 0.6813, w * 0.7813, h * 0.8125);
        canvas.drawPath(bodyPath, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
