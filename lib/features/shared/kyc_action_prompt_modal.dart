import 'dart:ui';
import 'package:flutter/material.dart';

void showKycActionPromptModal({
  required BuildContext context,
  required VoidCallback onVerify,
  bool isDiamond = true,
  bool isSilver = false,
}) {
  final accent = isDiamond ? const Color(0xFF3AC7FF) : isSilver ? Colors.white : const Color(0xFFF7CD57);
  final accentBg = isDiamond ? const Color(0xFF0A2A3B) : isSilver ? const Color(0xFF1D2530) : const Color(0xFF1D170D);
  final badgeLabel = isDiamond ? 'KYC UNLOCKS DIAMOND PURCHASE' : 'KYC UNLOCKS HIGHER LIMITS';
  final description = isDiamond
      ? 'Complete KYC to purchase diamonds.'
      : 'Complete KYC to unlock higher purchase limits.';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: 420,
      width: 390,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF111008),
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1710),
                  border: Border.all(color: const Color(0xFF3E3E3E)),
                ),
                child: const Icon(Icons.close, size: 14, color: Color(0xFF7E7E7E)),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 100, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3E3E),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -48, top: -64,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        width: 144, height: 144,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE784), Color(0xFFC88912)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(Icons.lock, color: Color(0xFF11130F), size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'KYC verification required',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Color(0xFFD5C7A8), fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); onVerify(); },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Complete KYC', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('I will do it later', style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
