import 'package:flutter/material.dart';

void showKycActionPromptModal({
  required BuildContext context,
  required VoidCallback onVerify,
  bool isDiamond = true,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: 390,
      width: 390,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF111008),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100, height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF3E3E3E),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          if (isDiamond)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2A3B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3AC7FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'KYC UNLOCKS DIAMOND PURCHASE',
                    style: TextStyle(
                      color: Color(0xFF3AC7FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
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
            isDiamond
                ? 'Complete KYC to purchase diamonds.'
                : 'Complete KYC to unlock higher purchase limits.',
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
                child: Text('Complete KYC', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
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
    ),
  );
}
