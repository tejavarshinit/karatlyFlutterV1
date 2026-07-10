import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class BankVerifyScreen extends StatefulWidget {
  const BankVerifyScreen({super.key});

  @override
  State<BankVerifyScreen> createState() => _BankVerifyScreenState();
}

class _BankVerifyScreenState extends State<BankVerifyScreen> {
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _ifscController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _accountController.text.isNotEmpty && _ifscController.text.isNotEmpty && _nameController.text.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.97, -0.38),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text('Verify Bank Account', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('We will deposit ₹1 to verify your account details.', style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 13)),
                const SizedBox(height: 20),
                _field('Account Number', _accountController, keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                _field('IFSC Code', _ifscController, upperCase: true),
                const SizedBox(height: 14),
                _field('Account Holder Name', _nameController),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFF7CD57), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The name on your bank account must match the name on your PAN card for successful verification.',
                          style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit
                        ? () => context.go(
                              AppRoutes.bankVerifyLoading,
                              extra: {
                                'accountNumber': _accountController.text.trim(),
                                'ifscCode': _ifscController.text.trim(),
                                'accountName': _nameController.text.trim(),
                              },
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7CD57),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Verify Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, bool upperCase = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: upperCase ? TextCapitalization.characters : TextCapitalization.none,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF7CD57))),
          ),
        ),
      ],
    );
  }
}
