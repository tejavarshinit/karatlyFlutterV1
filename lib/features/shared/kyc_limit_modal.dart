import 'package:flutter/material.dart';

void showKycLimitModal({
  required BuildContext context,
  required String title,
  required String message,
  bool needsKyc = true,
  String ctaLabel = 'Complete KYC',
  String laterLabel = 'I will do it later',
  required VoidCallback onCompleteKyc,
  required VoidCallback onLater,
  String metalType = 'gold',
}) {
  final isSilver = metalType == 'silver';
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0x4DE8B438)),
          gradient: const LinearGradient(begin: Alignment(0.145, -0.3939), end: Alignment.bottomRight,
            colors: [Color(0xFF503B15), Color(0xFF1C1408), Color(0xFF080603)]),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 80, offset: const Offset(0, 28))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 4, top: 4,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF7E7E7E)),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE784), Color(0xFFC88912)])),
                child: Icon(needsKyc ? Icons.lock : Icons.verified_user, color: const Color(0xFF11130F), size: 25)),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              Text(message,
                style: const TextStyle(fontSize: 13, color: Color(0xFFD5C7A8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); onCompleteKyc(); },
                child: Container(width: double.infinity, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)])),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(ctaLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                  ])),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); onLater(); },
                child: Text(laterLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}
