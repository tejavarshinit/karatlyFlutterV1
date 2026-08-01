import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  static const _steps = [
    _StepData('01', Icons.person_add_outlined, 'Create an Account', 'Sign up and verify your identity in minutes with a simple KYC process.'),
    _StepData('02', Icons.account_balance_wallet_outlined, 'Add Funds', 'Securely add money through UPI, bank transfer, or digital payment methods.'),
    _StepData('03', Icons.monetization_on_outlined, 'Buy Digital Gold', 'Purchase gold instantly at live market prices \u2014 start from as low as \u20b910.'),
    _StepData('04', Icons.download_outlined, 'Sell Anytime', 'Sell your gold anytime and receive instant payouts directly to your bank.'),
  ];

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
                const SizedBox(height: 12),
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildTitle(),
                const SizedBox(height: 8),
                const Text(
                  'Start investing in digital gold in just four simple steps',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 24),
                ..._steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildStepCard(step),
                )),
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
              onTap: () => context.go(AppRoutes.dashboard),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text('How It Works', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
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

  Widget _buildTitle() {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(text: 'How It ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          TextSpan(text: 'Works', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
        ],
      ),
    );
  }

  Widget _buildStepCard(_StepData step) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141414), Color(0xFF0B0B0B)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2E2E2E)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFEAB308), Color(0xFFCA8A04)]),
                ),
                child: Icon(step.icon, color: Colors.black, size: 24),
              ),
              const SizedBox(height: 16),
              Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(step.description, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), height: 1.5), textAlign: TextAlign.center),
            ],
          ),
        ),
        Positioned(
          right: 24,
          top: 16,
          child: Text(
            step.number,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0x4D2E2E2E)),
          ),
        ),
      ],
    );
  }
}

class _StepData {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  const _StepData(this.number, this.icon, this.title, this.description);
}
