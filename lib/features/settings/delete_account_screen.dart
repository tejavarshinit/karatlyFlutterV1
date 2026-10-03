import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

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
                const SizedBox(height: 24),
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('INSTRUCTIONS'),
                const SizedBox(height: 12),
                _buildInstructionCard(
                  icon: Icons.mail_outline,
                  title: 'Send an Email',
                  description:
                      'Please send an account deletion request to our support team at the email address below.',
                ),
                const SizedBox(height: 10),
                _buildInstructionCard(
                  icon: Icons.person_outline,
                  title: 'Include Your Username',
                  description:
                      'Mention your Karatly username in the email so we can locate your account.',
                ),
                const SizedBox(height: 10),
                _buildInstructionCard(
                  icon: Icons.phone_outlined,
                  title: 'Include Registered Mobile Number',
                  description:
                      'Provide the mobile number linked to your account for verification.',
                ),
                const SizedBox(height: 10),
                _buildInstructionCard(
                  icon: Icons.info_outline,
                  title: 'Reason for Deletion (Optional)',
                  description:
                      'You may include a reason for deleting your account. This helps us improve our service.',
                ),
                const SizedBox(height: 24),
                _buildEmailButton(),
                const SizedBox(height: 24),
                _buildNoteCard(),
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
              onTap: () => context.go(AppRoutes.profile),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Delete Account',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delete Account',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'If you would like to delete your Karatly account, please send an account deletion request to our support team.',
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.8), height: 1.5),
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
          letterSpacing: 1.2),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF202326)),
            child: Icon(icon, color: const Color(0xFFF7CD57), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                        color: Color(0xFF7E7E7E), fontSize: 10, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailButton() {
    return GestureDetector(
      onTap: () {
        // Launch email via url_launcher if available, otherwise just show
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0F1416),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Row(
          children: [
            const Icon(Icons.email_outlined,
                color: Color(0xFFF7CD57), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email Us',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('karatlyfinvest@gmail.com',
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style:
                          TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1510),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFFF7CD57), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Our support team will verify your details and process your account deletion request.',
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
