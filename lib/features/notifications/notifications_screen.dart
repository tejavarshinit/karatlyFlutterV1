import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildStayInLoopCard(),
                const SizedBox(height: 28),
                _buildSectionTitle('TODAY'),
                const SizedBox(height: 12),
                _buildNotificationItem(
                  icon: Icons.currency_rupee,
                  iconBg: const Color(0xFF0A8754),
                  title: 'Gold Purchase Successful',
                  subtitle: 'You purchased 0.5g of gold at ₹5,432/g',
                  time: '2m ago',
                ),
                _buildNotificationItem(
                  icon: Icons.trending_up,
                  iconBg: const Color(0xFFF7CD57),
                  title: 'Price Alert',
                  subtitle: 'Gold rate dropped below ₹5,400/g',
                  time: '1h ago',
                ),
                _buildNotificationItem(
                  icon: Icons.verified_user_outlined,
                  iconBg: const Color(0xFF2196F3),
                  title: 'KYC Verification Complete',
                  subtitle: 'Your KYC has been verified successfully',
                  time: '3h ago',
                ),
                _buildNotificationItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: const Color(0xFF9C27B0),
                  title: 'Funds Added',
                  subtitle: '₹1,000 added to your wallet via UPI',
                  time: '5h ago',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('YESTERDAY'),
                const SizedBox(height: 12),
                _buildNotificationItem(
                  icon: Icons.notifications_outlined,
                  iconBg: const Color(0xFFFF9800),
                  title: 'SIP Reminder',
                  subtitle: 'Your monthly SIP of ₹500 is due tomorrow',
                  time: '1d ago',
                ),
                _buildNotificationItem(
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFF607D8B),
                  title: 'Security Alert',
                  subtitle: 'New login detected from Mumbai, Maharashtra',
                  time: '1d ago',
                ),
                _buildNotificationItem(
                  icon: Icons.star_outline,
                  iconBg: const Color(0xFFF7CD57),
                  title: 'Reward Earned',
                  subtitle: 'You earned 50 Karatly Points for your purchase',
                  time: '1d ago',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('EARLIER'),
                const SizedBox(height: 12),
                _buildNotificationItem(
                  icon: Icons.info_outline,
                  iconBg: const Color(0xFF2196F3),
                  title: 'App Update Available',
                  subtitle: 'Version 2.6 is now available with new features',
                  time: '3d ago',
                ),
                _buildNotificationItem(
                  icon: Icons.gavel_outlined,
                  iconBg: const Color(0xFF795548),
                  title: 'Terms Updated',
                  subtitle: 'Our Terms & Conditions have been updated',
                  time: '5d ago',
                ),
                const SizedBox(height: 32),
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
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Notification',
              style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF7CD57).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '3 New',
                style: TextStyle(
                  color: Color(0xFFF7CD57),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildStayInLoopCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFF7CD57),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Stay in the Loop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Get notified about price alerts, transactions, and updates.',
            style: TextStyle(
              color: Color(0xFF7E7E7E),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFFBFBFBF),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg.withOpacity(0.15),
            ),
            child: Icon(icon, color: iconBg, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7E7E7E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF7E7E7E),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
