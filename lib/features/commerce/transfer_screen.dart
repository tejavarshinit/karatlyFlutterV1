import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _receiverController = TextEditingController();
  final _quantityController = TextEditingController();
  String _metalType = 'gold';
  double _goldBalance = 0;
  double _silverBalance = 0;
  bool _loading = false;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = (profile['uniqueId']?.toString() ?? profile['augmontUniqueId']?.toString() ?? LocalStorageService.getUserUniqueId() ?? '').trim();
    if (uniqueId.isEmpty) return;

    final api = ref.read(augmontApiProvider);
    final res = await api.fetchAugmontPassbook(uniqueId);
    if (!mounted || res['ok'] != true) return;
    final passbook = (res['passbook'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _goldBalance = double.tryParse(passbook['goldGrms']?.toString() ?? passbook['goldBalance']?.toString() ?? '0') ?? 0;
      _silverBalance = double.tryParse(passbook['silverGrms']?.toString() ?? passbook['silverBalance']?.toString() ?? '0') ?? 0;
    });
  }

  Future<void> _transfer() async {
    setState(() {
      _error = '';
      _success = '';
    });

    final receiverId = _receiverController.text.trim();
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final available = _metalType == 'gold' ? _goldBalance : _silverBalance;

    if (receiverId.isEmpty) {
      setState(() => _error = 'Please enter receiver ID');
      return;
    }
    if (quantity <= 0) {
      setState(() => _error = 'Please enter valid quantity');
      return;
    }
    if (quantity > available) {
      setState(() => _error = 'Insufficient balance');
      return;
    }

    final profile = LocalStorageService.getUserProfile() ?? {};
    final senderUniqueId = (profile['uniqueId']?.toString() ?? profile['augmontUniqueId']?.toString() ?? LocalStorageService.getUserUniqueId() ?? '').trim();

    setState(() => _loading = true);
    final api = ref.read(augmontApiProvider);
    final response = await api.createAugmontTransferOrder(
      request: {
        'senderUniqueId': senderUniqueId,
        'receiverUniqueId': receiverId,
        'metalType': _metalType,
        'quantity': quantity.toString(),
        'merchantTransactionId': 'TRF-${DateTime.now().millisecondsSinceEpoch}',
      },
    );
    setState(() => _loading = false);

    if (response['ok'] == true) {
      setState(() {
        _success = 'Transfer successful!';
        _receiverController.clear();
        _quantityController.clear();
      });
      await _loadBalances();
      await ref.read(authProvider.notifier).refreshAfterKyc();
    } else {
      setState(() => _error = response['message']?.toString() ?? 'Transfer failed');
    }
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = _metalType == 'gold' ? _goldBalance : _silverBalance;

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
          child: SingleChildScrollView(
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
                    Text('Transfer ${_metalType == 'gold' ? 'Gold' : 'Silver'}', style: const TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
                    const Spacer(),
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
                        child: const Icon(Icons.notifications_outlined, size: 14, color: Color(0xFFC1C1C1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF7CD57).withOpacity(0.2)),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF7CD57).withOpacity(0.16),
                        const Color(0xFF000000),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available ${_metalType == 'gold' ? 'Gold' : 'Silver'} Balance', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('${available.toStringAsFixed(4)} gms', style: const TextStyle(color: Color(0xFFF7CD57), fontSize: 30, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _typeButton('Gold', _metalType == 'gold', () => setState(() => _metalType = 'gold'))),
                    const SizedBox(width: 12),
                    Expanded(child: _typeButton('Silver', _metalType == 'silver', () => setState(() => _metalType = 'silver'))),
                  ],
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'Receiver Unique ID',
                  controller: _receiverController,
                  hint: 'e.g. AUG-USER-1234',
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'Quantity (gms)',
                  controller: _quantityController,
                  hint: '0.0000',
                  keyboardType: TextInputType.number,
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
                if (_success.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_success, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _transfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7CD57),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_loading ? 'Processing...' : 'Transfer Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? const Color(0xFFF7CD57) : Colors.white.withOpacity(0.05),
          border: Border.all(color: selected ? const Color(0xFFF7CD57) : Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white70, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF7E7E7E)),
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
