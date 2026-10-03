import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9755, -0.3792),
          radius: 1.04,
          colors: [Color(0xFF4A3A1E), Colors.black],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 88),
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildInfoCard(),
                const SizedBox(height: 16),
                const Text(
                  'These Terms and Conditions ("T&C") govern all transactions on the Karatly Platform. By clicking "I Agree" or placing any transaction, you agree to be bound by these T&C.',
                  style: TextStyle(
                      color: Color(0xFFBFBFBF), fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TERMS AND CONDITIONS:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 325,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1416),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _termsText,
                      style: const TextStyle(
                        color: Color(0xFFBFBFBF),
                        fontSize: 12,
                        height: 1.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
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
                  context.go(AppRoutes.profile);
                }
              },
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Terms & Condition',
                style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
          ],
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.notifications),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_outlined,
                    color: Colors.grey[400], size: 14),
                const Positioned(
                  right: 4,
                  top: 4,
                  child: SizedBox(
                      width: 5,
                      height: 5,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Color(0xFFEE0105),
                              shape: BoxShape.circle))),
                ),
              ],
            ),
          ),
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
          colors: [Color(0xFF1A1710), Color(0xFF0D0902)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7CD57), Color(0xFFB98324)],
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'KARATLY',
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Karatly Legal v2.6',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Last updated June 2026',
                    style: TextStyle(color: Color(0xFFBFBFBF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const String _termsText = '''
1 DEFINITIONS
Platform: www.karatly.net website and Karatly mobile application (iOS and Android).
GAP: Gold Accumulation Plan - digital gold/silver savings scheme powered by Augmont-Bullion.
Augmont-Bullion: Augmont Goldtech Private Limited - empanelled Bullion Partner and direct seller of Gold/Silver.
Sale Confirmation: Confirmation issued by Augmont-Bullion upon successful Gold/Silver purchase.
Live Rate - Purchase: Real-time Gold/Silver price per gram published by Augmont-Bullion.

2 ACCOUNT REGISTRATION AND KYC
• You must provide accurate, current, and complete information during registration.
• Mandatory two-factor KYC before any transaction: government-issued POI + POA + PAN + active Indian bank account + registered mobile number.
• PAN Card is mandatory for cumulative Gold/Silver purchases of Rs. 1,000 or more in a Financial Year.

3 PURCHASE AND IRREVOCABILITY
IRREVOCABILITY - Once Sale Confirmation is issued by Augmont-Bullion, the purchase is FINAL, BINDING, AND IRREVOCABLE. It cannot be cancelled, reversed, or suspended for any reason. The only exit from a confirmed position is the Sale-Back facility subject to the mandatory 48-hour holding period.

4 TITLE AND CUSTODY
Title and ownership of Gold/Silver purchased passes directly from Augmont-Bullion to the Customer at the moment of Sale Confirmation. Karatly never holds title to any Customer's Gold or Silver.

5 DELIVERY AND REDEMPTION
Customers may request physical delivery of Gold/Silver accumulated in their GAP account. Delivery is subject to making charges, delivery charges, and applicable taxes.

6 GOVERNING LAW
These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts located in Bangalore.
''';
