import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  static const _refundText = '''Refund, Cancellation and Return Policy

Last Updated: June 2026

CRITICAL RULE: Once Sale Confirmation is issued by Augmont-Bullion, a Gold or Silver purchase is FINAL AND IRREVOCABLE. There is NO refund on confirmed purchases. Use the SALE-BACK FACILITY (after 48 hours) to exit a position.

1. CANCELLATION POLICY
\u2022 Gold/Silver Purchases: Irrevocable once confirmed.
\u2022 Pending Orders: Auto-reversed if not confirmed within 2 hours.
\u2022 SIP: Can be paused or cancelled with 2 days' notice.
\u2022 Physical Redemption: Cancellation only within 2 hours of order placement AND before dispatch.

2. WHEN REFUNDS APPLY
\u2022 Payment debited but no Sale Confirmation issued.
\u2022 Duplicate payment charged.
\u2022 Overpayment detected during reconciliation.
\u2022 Redemption order cancelled pre-dispatch within window.

3. REFUND TIMELINES
\u2022 UPI: 24\u201348 hours.
\u2022 Net Banking: 3\u20135 Business Days.
\u2022 Cards: 3\u20137 Business Days.

4. RETURN POLICY
\u2022 Gold/Silver: Non-returnable once delivered. Quality complaints must be raised within 7 days.
\u2022 Diamond/Jewellery: Returns accepted within 7 days for damage or mismatch only.''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(context, 'Refund Policy'),
                const SizedBox(height: 24),
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildContent(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go(AppRoutes.dashboard),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFFF7CD57)),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.notifications),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 19, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2A28), Color(0xFF6C5123)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB28A3B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Policy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            'Last Updated: June 2026',
            style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: 350,
      child: SingleChildScrollView(
        child: Text(
          _refundText,
          style: const TextStyle(
            color: Color(0xFFBCBCBC),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
