import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/storage/local_storage.dart';

class DiamondPaymentSuccessScreen extends ConsumerWidget {
  const DiamondPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = _getPaymentContext();

    final paidAmount = ctx['amount'] ?? '0';
    final orderRef = ctx['merchantOrderRef'] ?? ctx['sabbpeOrderId'] ?? 'N/A';
    final diamondName = ctx['diamondName'] ?? 'Diamond';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF0A2A3B), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Success glow circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0167B8), Colors.black],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0084FF).withValues(alpha: 0.18),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Successful',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your diamond has been ordered successfully',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)),
                  ),
                  const SizedBox(height: 24),
                  // Order details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF3E3E3E)),
                      color: const Color(0xFF26313B),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Amount paid', '₹$paidAmount'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Diamond', diamondName),
                        const SizedBox(height: 12),
                        _buildDetailRow('Order Ref', '#$orderRef'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Status', 'Completed', isStatus: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Invoice Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3E3E3E)),
                      color: const Color(0xFF1A2530),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined, size: 20, color: Color(0xFF3AC7FF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Invoice Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(height: 4),
                              const Text('Your invoice will be generated within 1-2 business days and shipment will take 6-7 business days.', style: TextStyle(fontSize: 11, color: Color(0xFF7E7E7E), height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Shipment Address card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3E3E3E)),
                      color: const Color(0xFF1A2530),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF3AC7FF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shipment Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(height: 4),
                              const Text('Your invoice and shipment will be processed using your verified Aadhaar address.', style: TextStyle(fontSize: 11, color: Color(0xFF7E7E7E), height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Single full-width CTA
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(colors: [Color(0xFF0084FF), Color(0xFF004F99)]),
                      ),
                      child: const Center(
                        child: Text('Continue Shopping', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF15EE01).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15EE01)),
                ),
              )
            : Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildButton({required String label, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: isPrimary
              ? const LinearGradient(colors: [Color(0xFF0073CE), Color(0xFF004175)])
              : null,
          border: isPrimary ? null : Border.all(color: const Color(0xFF3E3E3E)),
          color: isPrimary ? null : const Color(0xFF1B1913),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getPaymentContext() {
    try {
      final raw = LocalStorageService.getDiamondPaymentContext();
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }
}
