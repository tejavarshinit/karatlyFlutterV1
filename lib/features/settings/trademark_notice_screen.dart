import 'package:flutter/material.dart';

class TrademarkNoticeScreen extends StatelessWidget {
  const TrademarkNoticeScreen({super.key});

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
                _buildHeader(context, 'Trademark Notice'),
                const SizedBox(height: 24),
                _buildTrademarkTable(),
                const SizedBox(height: 24),
                _buildSection(
                  'Platform Technology',
                  'All software, code, algorithms, user interface designs, graphics, logos, icons, and technical infrastructure powering the Karatly platform are the exclusive intellectual property of Karatly Technologies Pvt. Ltd. This includes but is not limited to the mobile application, website, APIs, data models, and proprietary trading algorithms. Unauthorized copying, modification, reverse engineering, or distribution of any part of the platform\'s technology is strictly prohibited and may result in legal action.',
                ),
                _buildSection(
                  'Content',
                  'All text, images, graphics, videos, animations, documentation, and other content published on the Karatly platform are protected under Indian copyright law (Copyright Act, 1957) and international intellectual property treaties. Users may not reproduce, distribute, display, or create derivative works from any content without prior written consent from Karatly. User-generated content posted on the platform remains the intellectual property of the user, but by posting, users grant Karatly a non-exclusive, worldwide, royalty-free license to use, display, and distribute such content in connection with the platform\'s services.',
                ),
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

  Widget _buildTrademarkTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trademark Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTableRow('Word Mark', 'KARATLY'),
          const Divider(color: Color(0xFF2E2E2E), height: 24),
          _buildTableRow('Proprietor', 'Karatly Technologies Pvt. Ltd.'),
          const Divider(color: Color(0xFF2E2E2E), height: 24),
          _buildTableRow('Class 36', 'Gold trading, digital gold, investment services'),
          const Divider(color: Color(0xFF2E2E2E), height: 24),
          _buildTableRow('Class 9', 'Mobile application, software platform'),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF7CD57),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF7E7E7E),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF7E7E7E),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
