import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/gold_flow_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/unique_id.dart';

class SilverSellFlowScreen extends ConsumerStatefulWidget {
  final int step;

  const SilverSellFlowScreen({super.key, this.step = 1});

  @override
  ConsumerState<SilverSellFlowScreen> createState() =>
      _SilverSellFlowScreenState();
}

class _SilverSellFlowScreenState extends ConsumerState<SilverSellFlowScreen> {
  final _weightController = TextEditingController(text: '0');
  double _rate = 0;
  double _balance = 0;
  bool _loading = true;
  bool _verifying = false;
  bool _bankLoading = false;
  Map<String, dynamic>? _primaryBank;
  Timer? _timer;

  String _uniqueId() {
    final stored = LocalStorageService.getUserUniqueId();
    if (stored != null && stored.isNotEmpty) return stored;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final phone = LocalStorageService.getUserPhone() ?? '';
    return UniqueIdHelper.buildMobileDobUniqueId(
      mobileNumber: phone,
      dateOfBirth: profile['dateOfBirth']?.toString() ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.step == 1) _loadData();
    if (widget.step == 3) _loadPayoutDestination();
    if (widget.step == 4) _startVerification();
  }

  Future<void> _loadPayoutDestination() async {
    final uid = _uniqueId();
    if (uid.isEmpty) return;
    setState(() => _bankLoading = true);
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final response = await api.fetchAugmontPrimaryUserBank(uniqueId: uid);
      final bank = response['bank'];
      if (mounted && bank is Map) {
        setState(() => _primaryBank = Map<String, dynamic>.from(bank));
        ref.read(goldFlowProvider.notifier).updateSellState(
              payoutMethod: 'bank',
              userBankId:
                  bank['userBankId']?.toString() ?? bank['id']?.toString(),
              bankName:
                  bank['bankName']?.toString() ?? bank['bank_name']?.toString(),
              accountNumber: bank['accountNumber']?.toString() ??
                  bank['account_number']?.toString(),
            );
      }
    } catch (_) {
      // The payout screen remains usable for adding a new account.
    } finally {
      if (mounted) setState(() => _bankLoading = false);
    }
  }

  Future<void> _loadData() async {
    final api = AugmontApi(ref.read(augmontDioProvider));
    final uid = _uniqueId();
    try {
      final results = await Future.wait([
        api.fetchLiveGoldRateSnapshot(),
        uid.isEmpty
            ? Future.value(<String, dynamic>{})
            : api.fetchAugmontPassbook(uid),
      ]);
      final rate = results[0];
      final passbook = results[1];
      final snapshot = rate['snapshot'] as Map<String, dynamic>?;
      final silver = snapshot?['silver'] as Map<String, dynamic>?;
      final balanceData = passbook['passbook'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _rate = ((silver?['sellPrice'] ?? silver?['buyPrice']) as num?)
                  ?.toDouble() ??
              0;
          _balance = double.tryParse((balanceData['silverGrms'] ??
                      balanceData['silverBalance'] ??
                      balanceData['balance'] ??
                      0)
                  .toString()) ??
              0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startVerification() {
    _verifying = true;
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('${AppRoutes.sellSilverVerified}?metal=silver');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weightController.dispose();
    super.dispose();
  }

  void _go(int step) {
    context.go('/sell-silver/$step?metal=silver');
  }

  double get _weight => double.tryParse(_weightController.text) ?? 0;
  double get _subtotal => _weight * _rate;
  double get _fee => (_subtotal * 0.005).roundToDouble();
  double get _payout => _subtotal - _fee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .94),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
              gradient: RadialGradient(
                  center: Alignment(.9, -1),
                  radius: 1.2,
                  colors: [Color(0xFF293341), Colors.black]),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(children: [
                _handle(),
                _header(),
                _rail(),
                const SizedBox(height: 8),
                if (widget.step == 1) _amountStep(),
                if (widget.step == 2) _reviewStep(),
                if (widget.step == 3) _payoutStep(),
                if (widget.step == 4) _verificationStep(),
                if (widget.step == 5) _verifiedStep(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _handle() => Container(
      width: 100,
      height: 10,
      decoration: BoxDecoration(
          color: const Color(0xFF3E3E3E),
          borderRadius: BorderRadius.circular(10)));

  Widget _header() => SizedBox(
        height: 56,
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
              left: 0,
              child: IconButton(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back, color: Colors.white))),
          Text(
              widget.step == 1
                  ? 'Redemption'
                  : widget.step == 2
                      ? 'Redemption Value'
                      : widget.step == 3
                          ? 'Confirm Account Details'
                          : widget.step == 4
                              ? 'Verifying'
                              : 'Verified',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          Positioned(
            right: 0,
            child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF3B3935),
                child: const Icon(Icons.verified_user,
                    size: 13, color: Color(0xFF15EE01))),
          ),
        ]),
      );

  Widget _rail() => Row(children: [
        _railItem('Amount', widget.step >= 1),
        _railItem('Review', widget.step >= 2),
        _railItem('Pay', widget.step >= 3),
      ]);

  Widget _railItem(String label, bool active) => Expanded(
      child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                height: 5,
                decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF3E3E3E),
                    borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.white : const Color(0xFF515151))),
          ])));

  Widget _card(Widget child,
          {Color color = const Color(0xFF1A2423), double radius = 20}) =>
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color,
              border: Border.all(color: const Color(0xFF3E3E3E)),
              borderRadius: BorderRadius.circular(radius)),
          child: child);

  Widget _amountStep() {
    if (_loading)
      return const Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Colors.white));
    return Column(children: [
      _card(
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YOUR HOLDINGS',
                  style: TextStyle(color: Color(0xFFA1A1A1), fontSize: 12)),
              Text('${_balance.toStringAsFixed(4)} g',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600)),
              Text('approximately Rs.${(_balance * _rate).round()}',
                  style: const TextStyle(color: Colors.white, fontSize: 10))
            ]),
            const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFBDBDBD),
                child: Text('KARATLY',
                    style: TextStyle(color: Colors.white, fontSize: 9))),
          ]),
          color: const Color(0xFF101820),
          radius: 10),
      const SizedBox(height: 8),
      _card(
          Row(children: [
            const Icon(Icons.show_chart, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Live Sell Rate',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        Text('Rs.${_rate.toStringAsFixed(0)}/g',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                      ]),
                  const Text('24K - 999.9 Pure',
                      style: TextStyle(color: Color(0xFF0EA300), fontSize: 10))
                ]))
          ]),
          color: const Color(0xFF1C2633)),
      const SizedBox(height: 8),
      _card(Column(children: [
        const Text('YOU SELL',
            style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24),
            decoration: const InputDecoration(
                suffixText: 'g',
                suffixStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5E5E5E)))),
            onChanged: (_) => setState(() {})),
        Text('approximately Rs.${_subtotal.round()}',
            style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 10)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final value in ['0.5', '1', '2'])
            OutlinedButton(
                onPressed: () {
                  _weightController.text = value;
                  setState(() {});
                },
                child: Text('${value}g')),
          OutlinedButton(
              onPressed: () {
                _weightController.text = _balance.toStringAsFixed(4);
                setState(() {});
              },
              child: const Text('Max'))
        ])
      ])),
      const SizedBox(height: 8),
      _payoutBar(),
      const SizedBox(height: 8),
      _button('Continue', () {
        ref.read(goldFlowProvider.notifier).updateSellState(
            amount: _subtotal,
            grams: _weight,
            rate: _rate,
            metalType: 'silver');
        _go(2);
      }),
    ]);
  }

  Widget _reviewStep() {
    final state = ref.watch(goldFlowProvider).sellState;
    return Column(children: [
      _card(
          Column(children: [
            _row('YOU ARE SELLING',
                '${(state.grams ?? 0).toStringAsFixed(4)} g'),
            _row('Sell Rate',
                'Rs.${(state.rate ?? _rate).toStringAsFixed(1)}/g'),
            _row('Quantity', '${(state.grams ?? 0).toStringAsFixed(4)} g'),
            _row('Sub total', 'Rs.${(state.amount ?? 0).toStringAsFixed(1)}'),
            _row('Platform fee (0.5%)',
                '-Rs.${((state.amount ?? 0) * .005).toStringAsFixed(2)}'),
            const Divider(color: Color(0xFF3E3E3E)),
            _row("You'll Receive",
                'Rs.${((state.amount ?? 0) * .995).toStringAsFixed(2)}')
          ]),
          color: const Color(0xFF1A2423)),
      const SizedBox(height: 12),
      _button('Continue', () => _go(3)),
    ]);
  }

  Widget _payoutStep() => Column(children: [
        _payoutBar(),
        const SizedBox(height: 16),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('PAYOUT DESTINATION',
                style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 12))),
        const SizedBox(height: 8),
        if (_bankLoading)
          _card(const Center(
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: Colors.white))))
        else if (_primaryBank != null)
          _option(
              Icons.account_balance, 'Bank account', 'Default payout account',
              () {
            ref
                .read(goldFlowProvider.notifier)
                .updateSellState(payoutMethod: 'bank');
          })
        else
          _card(const Text('No primary bank found. Add a bank or UPI account.',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12))),
        if (ref.watch(goldFlowProvider).sellState.upiId.isNotEmpty)
          _option(
              Icons.phone_android,
              ref.watch(goldFlowProvider).sellState.upiId,
              'UPI - Instant credit', () {
            ref
                .read(goldFlowProvider.notifier)
                .updateSellState(payoutMethod: 'upi');
          })
        else
          _option(Icons.phone_android, 'UPI ID', 'Instant credit', () {}),
        _option(Icons.add, 'Add new account', 'Bank or UPI',
            () => _showAddAccount()),
        const SizedBox(height: 8),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('Locked and encrypted with 256-bit SSL',
                style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 10))),
        const SizedBox(height: 12),
        _button('Continue', () {
          final payout = ref.read(goldFlowProvider).sellState;
          if (payout.payoutMethod.isEmpty &&
              _primaryBank == null &&
              payout.upiId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Add or select a payout account first')));
            return;
          }
          _go(4);
        }),
      ]);

  Widget _verificationStep() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 90),
      child: Column(children: [
        SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF9E9E9E))),
        SizedBox(height: 20),
        Text('Verifying',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text('Adding account details',
            style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 12))
      ]));

  Widget _verifiedStep() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(children: [
        const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFF15EE01),
            child: Icon(Icons.check, color: Colors.black, size: 42)),
        const SizedBox(height: 18),
        const Text('Account Verified',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your payout details have been added successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9E9E9E))),
        const SizedBox(height: 24),
        _button('Back to payout destination', () => _go(3))
      ]));

  Widget _payoutBar() => _card(
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("You'll Receive",
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
        Text('Rs.${_payout.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
      ]),
      color: const Color(0xFF19160F));
  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
      ]));
  Widget _option(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
              onTap: onTap,
              child: _card(Row(children: [
                CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(icon, color: Colors.white, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFF7E7E7E), fontSize: 10))
                    ])),
                const Icon(Icons.chevron_right, color: Colors.white)
              ]))));
  Widget _button(String text, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
          child: Text(text)));

  void _showAddAccount() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF201B0F),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.phone_android, color: Colors.white),
                  title: const Text('UPI ID',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('${AppRoutes.sellSilverUpi}?metal=silver');
                  }),
              ListTile(
                  leading:
                      const Icon(Icons.account_balance, color: Colors.white),
                  title: const Text('Bank Details',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('${AppRoutes.sellSilverBank}?metal=silver');
                  })
            ])));
  }
}
