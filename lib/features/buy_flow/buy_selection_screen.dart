import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/services/rate_provider.dart';
import '../shared/karatly_circle.dart';

class BuySelectionScreen extends ConsumerWidget {
  final String metalType;

  const BuySelectionScreen({super.key, this.metalType = 'gold'});

  bool get _isSilver => metalType == 'silver';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateState = ref.watch(rateProvider);
    final buyPrice = _isSilver
        ? (rateState.currentRate?.silver.buyPrice ?? 0)
        : (rateState.currentRate?.buyPrice ?? 0);
    final loading = rateState.loading;
    final isSilver = _isSilver;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      body: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.86),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          gradient: RadialGradient(
            center: const Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [isSilver ? const Color(0xFF293341) : const Color(0xFF4A3A1E), Colors.black],
          ),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 60, offset: Offset(0, -24))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.02), Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.35)],
                      stops: const [0, 0.18, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Column(
                  children: [
                    // Drag handle
                    Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFF3E3E3E), borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 16),

                    // Header
                    SizedBox(
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: GestureDetector(
                              onTap: () => context.go(AppRoutes.home),
                              child: const SizedBox(width: 24, height: 24, child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white)),
                            ),
                          ),
                          Center(
                            child: Text(
                              isSilver ? 'Buy Digital Silver' : 'Buy Digital Gold',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(color: Color(0xFF3B3935), shape: BoxShape.circle),
                              child: const Icon(Icons.shield, size: 12, color: Color(0xFF15EE01)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Rate card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSilver ? Colors.white : const Color(0xFFE8B438)),
                        gradient: LinearGradient(
                          begin: Alignment(2.45, 0.38), end: Alignment(-0.45, 0.55),
                          colors: isSilver
                              ? [const Color(0xFF495C73), const Color(0xFF0D1117)]
                              : [const Color(0xFF6C5123), const Color(0xFF1E2A28)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSilver ? 'Silver Live Rate' : 'Gold Live Rate',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1A1)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loading ? 'Loading...' : buyPrice > 0 ? '₹${buyPrice.toInt()}/g' : 'Unavailable',
                                  style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w600,
                                    color: isSilver ? Colors.white : null,
                                  ),
                                ),
                                if (!isSilver)
                                  ShaderMask(
                                    shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFF917833)]).createShader(b),
                                    child: Text(' '),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, size: 12, color: Color(0xFF0EA300)),
                                    const SizedBox(width: 4),
                                    Text(
                                      loading ? 'Fetching live rate...' : 'Live · refreshed 2s ago',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF0EA300)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          KaratlyCircle(size: 60, metalType: metalType),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Digital option
                    GestureDetector(
                      onTap: () => context.go('/buy/buy/1?metal=$metalType'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: isSilver
                                ? [const Color(0xFF1C2633), const Color(0xFF0D1117)]
                                : [const Color(0xFF2A2010), const Color(0xFF1A1408)],
                          ),
                          border: Border.all(
                            color: isSilver ? Colors.white.withValues(alpha: 0.19) : const Color(0xFFE8B438).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: isSilver
                                      ? [const Color(0xFFE8EEF5), const Color(0xFF8E9AAA)]
                                      : [const Color(0xFFF3C751), const Color(0xFFBE8928)],
                                ),
                              ),
                              child: Center(
                                child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSilver ? 'Digital Silver' : 'Digital Gold',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                  Text(
                                    'Buy Instant ${isSilver ? "Digital Silver" : "Digital Gold"}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: isSilver ? Colors.white : const Color(0xFFE8B438)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
             ],
           ),
         ),
       ),
     );
   }
}
