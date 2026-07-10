import 'package:flutter/material.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

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
                _buildIntroParagraph(),
                const SizedBox(height: 16),
                _buildScrollableContent(),
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
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFFF7CD57)),
            ),
          ],
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1D170D),
            border: Border.all(color: const Color(0xFFE8B438)),
          ),
          child: Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1F0A), Color(0xFF1D170D)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8D862), Color(0xFFD59B12)],
              ),
            ),
            child: const Center(
              child: Text(
                'KARATLY',
                style: TextStyle(
                  color: Color(0xFFC89111),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund, Cancellation & Return',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Last updated June 2026',
                  style: TextStyle(
                    color: Color(0xFF7E7E7E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroParagraph() {
    return const Text(
      'Karatly is committed to transparency in all its transactions. Please review our refund, cancellation, and return policy below.',
      style: TextStyle(
        color: Color(0xFF7E7E7E),
        fontSize: 12,
        height: 1.6,
      ),
    );
  }

  Widget _buildScrollableContent() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RefundSection(
              heading: '1. Refund Policy',
              body:
                  'All transactions on Karatly are final once confirmed by the user. Digital gold purchases cannot be refunded once the order is executed. However, if a payment is deducted but the gold is not credited to your account due to a technical error, Karatly will investigate and process a refund within 5-7 business days. Refunds will be credited to the original payment method used for the transaction. In case of any discrepancy, users must report the issue within 48 hours of the transaction via the Help Center or by contacting support@karatly.net.',
            ),
            _RefundSection(
              heading: '2. Cancellation Policy',
              body:
              'Users may cancel a pending buy order before it is executed on the platform. Once an order is confirmed and executed (gold is credited to the user\'s account), it cannot be cancelled. SIP (Systematic Investment Plan) orders can be cancelled or modified at any time before the scheduled debit date. Recurring orders that have already been debited cannot be cancelled for that cycle. Karatly reserves the right to cancel orders in cases of payment fraud, regulatory requirements, or system errors, with full refund of any amounts collected.',
            ),
            _RefundSection(
              heading: '3. Return Policy',
              body:
              'Digital gold held on Karatly is not a physical product subject to traditional return policies. Users can sell their digital gold holdings at any time at the prevailing market rate through the platform\'s sell feature. There is no lock-in period for digital gold purchased on Karatly. If a user has opted for physical gold delivery (coins or bars), returns are not accepted once delivered unless the product is damaged or defective, in which case the user must contact support within 48 hours of delivery with photographic evidence.',
            ),
            _RefundSection(
              heading: '4. Dispute Resolution',
              body:
              'In the event of a dispute regarding any transaction, refund, or cancellation, users should first reach out to Karatly support through the Help Center. Our team will investigate the matter and respond within 5 business days. If the dispute is not resolved satisfactorily, it may be escalated to arbitration in accordance with the Arbitration and Conciliation Act, 1996. The venue of arbitration shall be New Delhi, India. These terms are governed by the laws of India.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RefundSection extends StatelessWidget {
  final String heading;
  final String body;

  const _RefundSection({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF7E7E7E),
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
