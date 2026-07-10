import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class PaymentResultScreen extends StatelessWidget {
  final String orderId;
  final String status;
  const PaymentResultScreen({super.key, required this.orderId, this.status = 'success'});

  @override
  Widget build(BuildContext context) {
    final isSuccess = status.toLowerCase() == 'success';
    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Payment Successful' : 'Payment Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
              ),
              const SizedBox(height: 8),
              Text('Order ID: $orderId', style: const TextStyle(color: Color(0xFF9E9A94))),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
