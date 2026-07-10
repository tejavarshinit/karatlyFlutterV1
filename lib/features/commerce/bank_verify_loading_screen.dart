import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../shared/widgets/success_animation.dart';

class BankVerifyLoadingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> details;

  const BankVerifyLoadingScreen({super.key, this.details = const {}});

  @override
  ConsumerState<BankVerifyLoadingScreen> createState() => _BankVerifyLoadingScreenState();
}

class _BankVerifyLoadingScreenState extends ConsumerState<BankVerifyLoadingScreen> {
  Timer? _timer;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _runVerification();
  }

  Future<void> _runVerification() async {
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = (profile['uniqueId']?.toString() ?? profile['augmontUniqueId']?.toString() ?? LocalStorageService.getUserUniqueId() ?? '').trim();

    if (uniqueId.isNotEmpty) {
      final api = ref.read(augmontApiProvider);
      await api.createAugmontUserBank(
        uniqueId: uniqueId,
        request: {
          'accountNumber': widget.details['accountNumber']?.toString() ?? '',
          'ifscCode': widget.details['ifscCode']?.toString() ?? '',
          'accountName': widget.details['accountName']?.toString() ?? '',
        },
      );
    }

    _timer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      setState(() => _success = true);
      final storedProfile = LocalStorageService.getUserProfile() ?? {};
      await LocalStorageService.setUserProfile({
        ...storedProfile,
        'bankVerified': true,
        'kycStatus': 'Verified',
      });
      await ref.read(authProvider.notifier).refreshAfterKyc();
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) context.go(AppRoutes.profile);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: const [
                    Text('Verifying', style: TextStyle(color: Color(0xFFF7CD57), fontSize: 14)),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: _BankVerifyBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankVerifyBody extends StatelessWidget {
  const _BankVerifyBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SuccessAnimation(text: 'Bank Verified!'),
        SizedBox(height: 14),
        Text('Your account is ready for transactions.', style: TextStyle(color: Color(0xFFB4B0B0), fontSize: 13)),
      ],
    );
  }
}
