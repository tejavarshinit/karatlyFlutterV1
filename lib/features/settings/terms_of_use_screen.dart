import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      SizedBox(height: 24),
                      _buildBlockquote(),
                      SizedBox(height: 24),
                      _section('1 ABOUT KARATLY', _aboutKaratly),
                      SizedBox(height: 20),
                      _section('2 WHO CAN USE THE PLATFORM \u2014 ELIGIBILITY', ''),
                      _eligibilityList(),
                      SizedBox(height: 20),
                      _section('3 KARATLY\'S ROLE \u2014 INTERMEDIARY ONLY', _intermediaryRole),
                      SizedBox(height: 32),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            const Text('Terms of Use', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
          ],
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.notifications),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 14),
                const Positioned(right: 4, top: 4, child: SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEE0105), shape: BoxShape.circle)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _aboutKaratly = '''Karatly Finvest Technology India Private Limited (CIN: U70200KA2026PTC219560) is a digital financial technology company registered under the Companies Act, 2013. Karatly operates the Karatly Platform that enables the purchase, accumulation, sale-back, and physical redemption of digital Gold, Silver, Ornaments, Diamonds, and related savings products through a Gold Accumulation Plan (GAP) and Systematic Investment Plan (SIP).
Karatly''s Registered Office: BBMP Khata No. 41/2, 6 SEC, GVR Spaces, Site No. 2, HSR Layout, Bangalore South, Karnataka \u2013 560102. Authorised signatory: Mr. Hemanth Veeramalla, Director.''';

  static const _eligibilityItems = [
    'You are at least 18 years of age. Persons under 18 are strictly prohibited from registering or transacting.',
    'You are a resident of India and are accessing the Platform from within India.',
    'You have the legal capacity to enter into binding contracts under Indian law and are not under any legal disability.',
    'You are not prohibited from using financial, investment, or precious metal services under any applicable Indian or international law.',
    'You hold a valid Indian bank account, a registered Indian mobile number, and a valid PAN Card.',
    'You have successfully completed Karatly\'s mandatory KYC verification process.',
    'Your use of the Platform is for lawful personal, non-commercial purposes only.',
  ];

  static const _intermediaryRole = '''Karatly is a digital intermediary platform and technology service provider operating under Section 79 of the Information Technology Act, 2000. KARATLY IS NOT THE SELLER, MANUFACTURER, CUSTODIAN, OR GUARANTOR of any Gold, Silver, Ornament, Diamond, or precious metal product offered through the Platform.
Gold and Silver transactions are executed directly between the Customer and Karatly''s empanelled Bullion Partner \u2014 currently Augmont Goldtech Private Limited ('Augmont-Bullion'). The legal contract for purchase is formed directly between you and Augmont-Bullion at the moment of Sale Confirmation.''';

  static Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Terms of Use', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
        const SizedBox(height: 4),
        const Text('Rules governing access to and use of the Karatly Platform', style: TextStyle(fontSize: 12, color: Color(0x80FFFFFF))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Effective Date:', style: TextStyle(fontSize: 10, color: Color(0x66FFFFFF))),
                    SizedBox(height: 4),
                    Text('June 2026', style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Version:', style: TextStyle(fontSize: 10, color: Color(0x66FFFFFF))),
                    SizedBox(height: 4),
                    Text('1.0', style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform:', style: TextStyle(fontSize: 10, color: Color(0x66FFFFFF))),
                    SizedBox(height: 4),
                    Text('Karatly App', style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact:', style: TextStyle(fontSize: 10, color: Color(0x66FFFFFF))),
                    SizedBox(height: 4),
                    Text('legal@karatly.net', style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildBlockquote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: const Color(0xFFF7CD57).withOpacity(0.5), width: 4)),
      ),
      child: const Text(
        'These Terms of Use (\'TOU\') constitute a legally binding agreement between you (\'User\', \'you\', \'your\') and Karatly Finvest Technology India Private Limited (\'Karatly\') under the Indian Contract Act, 1872. By accessing or using the Karatly Platform in any way, you unconditionally agree to these Terms of Use. If you do not agree, you must immediately stop using the Platform.',
        style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF), fontStyle: FontStyle.italic, height: 1.5),
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.5)),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF), height: 1.6)),
        ],
      ],
    );
  }

  static Widget _eligibilityList() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _eligibilityItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\u2022 ', style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF), height: 1.5)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
