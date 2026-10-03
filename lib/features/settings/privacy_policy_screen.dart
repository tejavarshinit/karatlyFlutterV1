import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _privacyText = '''Privacy Policy

Last Updated: June 2026

1. PERSONAL DATA WE COLLECT
\u2022 Identity and KYC Data: Full legal name, date of birth, gender, PAN Card, Aadhaar (tokenised), and residential address.
\u2022 Financial Data: Bank account details, UPI VPA, and transaction history.
\u2022 Device and Technical Data: IP address, device ID, device model, and operating system.
\u2022 Communication Data: Email address and registered mobile number.

2. WHY WE COLLECT YOUR DATA \u2014 LAWFUL BASIS
\u2022 Consent + Legal Obligation (RBI KYC Master Direction, PMLA 2002).
\u2022 Performance of Contract (Indian Contract Act 1872) for processing transactions.
\u2022 Legitimate Purpose for fraud detection and AML monitoring.

3. YOUR RIGHTS
Under DPDPA 2023, you have the right to access, correct, erase, and nominate a person for your data. You also have the right to withdraw consent at any time.

4. DATA SHARING
We share data with Augmont Goldtech Private Limited and SabbPe (Payment Aggregator) for transaction processing and legal compliance. We never sell your data.

5. DATA SECURITY
We use AES-256 encryption for data at rest and TLS 1.2/1.3 for data in transit. Two-factor authentication is mandatory for all accounts.''';

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
                _buildHeader(context, 'Privacy Policy'),
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
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
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
            'Privacy Policy',
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
    return Text(
      _privacyText,
      style: const TextStyle(
        color: Color(0xFFBCBCBC),
        fontSize: 12,
        height: 1.5,
      ),
    );
  }
}
