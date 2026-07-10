import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                  'Karatly Privacy v2.6',
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
      'At Karatly, we are committed to protecting your privacy and safeguarding your personal data. This Privacy Policy explains how we collect, use, disclose, and protect your information when you use our platform.',
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
            _PrivacySection(
              heading: '1. Personal Data We Collect',
              body:
                  'When you use Karatly, we may collect the following categories of personal data: identity information (full name, date of birth, gender), contact information (mobile number, email address, postal address), financial information (bank account details, UPI IDs, transaction history), identity verification documents (PAN card, Aadhaar number, photographs for KYC compliance), device and usage data (IP address, device type, operating system, app usage patterns), and gold transaction data (purchase history, holdings, sell orders). We collect this data only when necessary to provide and improve our services, comply with regulatory requirements, and ensure the security of your account.',
            ),
            _PrivacySection(
              heading: '2. Lawful Basis for Processing',
              body:
                  'We process your personal data based on the following lawful grounds: (a) Performance of a Contract — processing is necessary to provide you with Karatly\'s services as per our Terms and Conditions; (b) Legal Obligation — processing is required to comply with applicable Indian laws including the Prevention of Money Laundering Act, Income Tax Act, and RBI regulations; (c) Legitimate Interest — processing is necessary for fraud prevention, platform security, and service improvement; (d) Consent — where you have given explicit consent for specific processing activities such as marketing communications.',
            ),
            _PrivacySection(
              heading: '3. Your Rights',
              body:
                  'You have the following rights regarding your personal data: Right to Access — you may request a copy of all personal data we hold about you. Right to Correction — you may request correction of inaccurate or incomplete data. Right to Erasure — you may request deletion of your data, subject to regulatory retention requirements. Right to Restriction — you may request restriction of processing in certain circumstances. Right to Data Portability — you may request your data in a structured, machine-readable format. To exercise any of these rights, please contact our Data Protection Officer at privacy@karatly.net.',
            ),
            _PrivacySection(
              heading: '4. Data Sharing and Disclosure',
              body:
                  'We may share your personal data with the following categories of recipients: Vault partners and custodians (for gold storage and insurance purposes), payment processors (for transaction facilitation), regulatory authorities (as required by law), KYC verification agencies (for identity verification), analytics providers (in anonymized/aggregated form), and legal advisors (in case of disputes or legal proceedings). We do not sell your personal data to third parties for their marketing purposes. All data sharing is governed by strict contractual obligations and data protection agreements.',
            ),
            _PrivacySection(
              heading: '5. Data Security',
              body:
                  'We implement robust technical and organizational measures to protect your personal data, including: AES-256 encryption for data at rest, TLS 1.3 encryption for data in transit, multi-factor authentication for account access, regular security audits and penetration testing, access controls with role-based permissions, continuous monitoring and intrusion detection systems, and regular employee training on data protection practices. While we strive to protect your data, no method of transmission over the internet or electronic storage is 100% secure. We encourage you to take precautions to protect your own account credentials.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String heading;
  final String body;

  const _PrivacySection({required this.heading, required this.body});

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
