import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/kyc_limit_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/gold_flow_provider.dart';
import '../../core/utils/money.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/unique_id.dart';
import '../shared/step_rail.dart';
import '../shared/rate_card.dart';
import '../shared/karatly_circle.dart';
import '../shared/feature_chip.dart';
import '../shared/embedded_payment_gateway.dart';
import '../shared/kyc_limit_modal.dart';

/// Buy flow screen with 5 steps matching reference BuyFlow.tsx
class BuyScreen extends ConsumerStatefulWidget {
  final int step;
  final String metalType;

  const BuyScreen({super.key, this.step = 1, this.metalType = 'gold'});

  @override
  ConsumerState<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends ConsumerState<BuyScreen>
    with TickerProviderStateMixin {
  // Flow state
  String _mode = 'amount';
  final TextEditingController _amountController =
      TextEditingController(text: '');
  final TextEditingController _weightController =
      TextEditingController(text: '');
  int _itemCount = 1;

  // Stored values from previous steps (restored from GoldFlowProvider)
  double _storedPreTaxAmount = 0;
  double _storedGrams = 0;
  double _storedGst = 0;
  double _storedTotalPaid = 0;
  double _storedRate = 0;
  bool _hasStoredValues = false;

  // KYC limit state
  bool _kycLimitExceeded = false;
  late AnimationController _shakeController;
  late AnimationController _wiggleController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(_shakeController);
    _wiggleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    if (widget.step == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(kycLimitProvider.notifier).fetchKycLimit();
      });
    }
    if (widget.step > 1) {
      final buyState = ref.read(goldFlowProvider).buyState;
      if (buyState.amount > 0) {
        _storedPreTaxAmount = buyState.amount;
        _storedGrams = buyState.grams;
        _storedGst = buyState.gst;
        _storedTotalPaid = buyState.totalPaid;
        _storedRate = buyState.rate;
        _hasStoredValues = true;
      }
    }
    if (_amountController.text.isEmpty) _amountController.text = '100';
    if (_weightController.text.isEmpty) _weightController.text = '1';
  }

  String get _metalType => widget.metalType;
  bool get _isGold => _metalType == 'gold';
  bool get _isSilver => _metalType == 'silver';

  double _getLiveRate() {
    if (_hasStoredValues && _storedRate > 0) return _storedRate;
    final rateState = ref.read(rateProvider);
    if (_isSilver) {
      return rateState.currentRate?.silver.buyPrice ?? 0;
    }
    return rateState.currentRate?.buyPrice ?? 0;
  }

  double get _baseAmount {
    if (_hasStoredValues) return _storedPreTaxAmount;
    final liveRate = _getLiveRate();
    if (_mode == 'weight') {
      final weight = double.tryParse(_weightController.text) ?? 0;
      return MoneyHelper.truncateMoney(weight * liveRate);
    }
    return MoneyHelper.truncateMoney(
        double.tryParse(_amountController.text) ?? 0);
  }

  double get _amount => _hasStoredValues
      ? _storedPreTaxAmount
      : MoneyHelper.truncateMoney(_baseAmount * _itemCount);
  double get _gst =>
      _hasStoredValues ? _storedGst : MoneyHelper.truncateMoney(_amount * 0.03);
  double get _payableNow => _hasStoredValues
      ? _storedTotalPaid
      : MoneyHelper.truncateMoney(_amount + _gst);
  double get _quantity {
    if (_hasStoredValues) return _storedGrams;
    final liveRate = _getLiveRate();
    return liveRate > 0 ? _amount / liveRate : 0;
  }

  String _resolveUniqueId() {
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty)
      return storedUniqueId;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = profile['uniqueId']?.toString();
    if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final dob = profile['dateOfBirth']?.toString() ?? '';
      return UniqueIdHelper.buildMobileDobUniqueId(
          mobileNumber: phone, dateOfBirth: dob);
    }
    return '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _weightController.dispose();
    _shakeController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final parsed = double.tryParse(value) ?? 0;
    final state = ref.read(kycLimitProvider);
    final exceeded = !state.isKycVerified &&
        parsed > 0 &&
        parsed > state.remainingLimitPreTax;
    setState(() {
      _kycLimitExceeded = exceeded;
    });
    if (exceeded) {
      _shakeController.forward(from: 0);
      _wiggleController.repeat(reverse: true);
    } else {
      _wiggleController.stop();
    }
  }

  double get _wiggleValue => math.sin(_wiggleController.value * 2 * math.pi);

  void _onPresetTap(dynamic value) {
    setState(() {
      if (_mode == 'weight') {
        _weightController.text = value.toString();
      } else {
        _amountController.text = value.toString();
      }
    });
  }

  void _continueToNext() async {
    // KYC limit check only in Step 1 (Buy1)
    if (widget.step == 1) {
      final authState = ref.read(authProvider);
      final isKycDone = authState.user?.kycApproved == true;
      final kycState = ref.read(kycLimitProvider);
      if (!isKycDone && _payableNow > kycState.remainingLimit) {
        final uniqueId = _resolveUniqueId();
        if (uniqueId.isNotEmpty) {
          try {
            final api = AugmontApi(ref.read(augmontDioProvider));
            final results = await Future.wait([
              api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'gold'),
              api.fetchInvestmentSummary(
                  uniqueId: uniqueId, metalType: 'silver'),
            ]);
            final goldUsed =
                (results[0]['totalBuyPostTaxAmount'] as num?)?.toDouble() ?? 0;
            final silverUsed =
                (results[1]['totalBuyPostTaxAmount'] as num?)?.toDouble() ?? 0;
            final fyTotal = goldUsed + silverUsed;
            final remaining = (1000 - fyTotal).clamp(0, 1000);
            if (_payableNow > remaining) {
              if (!mounted) return;
              await showDialog(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.black.withValues(alpha: 0.7),
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0x4DE8B438)),
                      gradient: const LinearGradient(
                          begin: Alignment(0.145, -0.3939),
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF503B15),
                            Color(0xFF1C1408),
                            Color(0xFF080603)
                          ]),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 80,
                            offset: const Offset(0, 28))
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close,
                                size: 18, color: Color(0xFF7E7E7E)),
                          ),
                        ),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(17),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFFE784),
                                    Color(0xFFC88912)
                                  ])),
                              child: const Icon(Icons.lock,
                                  color: Color(0xFF11130F), size: 25)),
                          const SizedBox(height: 16),
                          const Text('Purchase limit reached',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(
                            'This purchase exceeds your ₹${remaining.toInt()} non-KYC limit (incl. GST). Complete KYC to proceed.',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFD5C7A8)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              context.go('/kyc-verification');
                            },
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFED75D),
                                    Color(0xFFECB000),
                                    Color(0xFFD48D00)
                                  ])),
                              child: Center(
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    const Text('Complete KYC',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward,
                                        size: 14, color: Colors.black),
                                  ])),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Text('I will do it later',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF7E7E7E))),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
              return;
            }
          } catch (_) {}
        }
      }
    }

    final nextStep = widget.step + 1;
    final preTax = _hasStoredValues ? _storedPreTaxAmount : _baseAmount;
    final grams = _hasStoredValues ? _storedGrams : _quantity;
    final gst = _hasStoredValues ? _storedGst : _gst;
    final totalPaid = _hasStoredValues ? _storedTotalPaid : _payableNow;
    final rate = _hasStoredValues ? _storedRate : _getLiveRate();

    ref.read(goldFlowProvider.notifier).updateBuyState(
          amount: preTax,
          grams: grams,
          gst: gst,
          totalPaid: totalPaid,
          rate: rate,
          metalType: _metalType,
        );

    if (!mounted) return;
    if (nextStep <= 5) {
      context.go('/buy/buy/$nextStep?metal=$_metalType');
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _goBack() {
    if (widget.step > 1) {
      context.go('/buy/buy/${widget.step - 1}?metal=$_metalType');
    } else {
      context.go(AppRoutes.home);
    }
  }

  Color _getGradientStart() {
    return _isSilver ? const Color(0xFF293341) : const Color(0xFF4A3A1E);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(rateProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
            gradient: RadialGradient(
              center: const Alignment(0.94, -0.95),
              radius: 1.2,
              colors: [_getGradientStart(), Colors.black],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 60,
                offset: Offset(0, -24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.02),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.35),
                        ],
                        stops: const [0, 0.18, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDragHandle(),
                      _buildHeader(),
                      const SizedBox(height: 8),
                      Flexible(child: _buildStepContent()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 100,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF3E3E3E),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = {
      1: 'Buy ${_isSilver ? "Silver" : "Gold"}',
      2: 'Review Order',
      3: 'Payment',
      4: 'Processing',
      5: 'Success',
    };

    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: GestureDetector(
              onTap: _goBack,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              titles[widget.step] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF3B3935),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield,
                size: 12,
                color: Color(0xFF15EE01),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (widget.step) {
      case 1:
        return _buildStep1Amount();
      case 2:
        return _buildStep2Review();
      case 3:
        return _buildStep3Payment();
      case 4:
        return _buildStep4Processing();
      case 5:
        return _buildStep5Success();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Amount Selection ────────────────────────────────────────────────

  Widget _buildStep1Amount() {
    final presets =
        _mode == 'weight' ? [0.5, 1.0, 2.0, 5.0] : [100, 500, 1000, 5000];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Step rails
          Row(
            children: [
              Expanded(
                  child: StepRail(
                      label: 'Amount', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Review', metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Pay', metalType: _metalType)),
            ],
          ),
          const SizedBox(height: 4),

          // Rate card
          RateCard(
            label: _isGold ? '24K - 999.9 Pure' : '99.9% Pure Silver',
            rateText: 'Rs.${_getLiveRate().toInt().toString()}/g',
            subtitle: 'Live - from Augmont',
            metalType: _metalType,
          ),
          const SizedBox(height: 4),

          // Amount/Weight toggle
          _buildModeToggle(),
          const SizedBox(height: 4),

          // Pre-tax amount input
          _buildAmountInput(),
          const SizedBox(height: 4),

          // Preset buttons
          _buildPresets(presets),
          const SizedBox(height: 6),

          // Feature chips
          Row(
            children: [
              Expanded(
                child: FeatureChip(
                  icon: Icons.shield,
                  label: 'Insured 100%',
                  metalType: _metalType,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FeatureChip(
                  icon: Icons.lock,
                  label: 'BIS Vault',
                  metalType: _metalType,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FeatureChip(
                  icon: Icons.circle,
                  label: '999.9 Pure',
                  metalType: _metalType,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Payable now bar
          _buildPayableBar(),
          const SizedBox(height: 4),

          // Continue button
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2E2A1A)),
        color: const Color(0xFF1A1710),
      ),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF252218),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _mode == 'amount' ? 0 : null,
              right: _mode == 'weight' ? 0 : null,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.44,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: _isSilver
                      ? const LinearGradient(colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFB8B8B8),
                          Color(0xFF8A8A8A)
                        ])
                      : const LinearGradient(colors: [
                          Color(0xFFF7CD57),
                          Color(0xFFDCA520),
                          Color(0xFFC49012)
                        ]),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'amount'),
                    child: Center(
                      child: Text(
                        'Buy Amount (Rs.)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mode == 'amount'
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _mode == 'amount'
                              ? const Color(0xFF1A1710)
                              : const Color(0xFF8A8578),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'weight'),
                    child: Center(
                      child: Text(
                        'By Weight (g)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mode == 'weight'
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _mode == 'weight'
                              ? const Color(0xFF1A1710)
                              : const Color(0xFF8A8578),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E4E4E)),
        color: const Color(0xFF21211A),
      ),
      child: Column(
        children: [
          const Text(
            'PRE-TAX AMOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _kycLimitExceeded
                        ? Colors.red
                        : const Color(0xFF5E5E5E)),
                color: const Color(0xFF37372E),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_mode == 'weight')
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 36)),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    )
                  else
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 36)),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _onAmountChanged,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    _mode == 'weight' ? 'g' : '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBCBCBC),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_kycLimitExceeded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'KYC limit exceeded',
                style: TextStyle(color: Colors.red[400], fontSize: 10),
              ),
            ),
          const SizedBox(height: 8),
          // Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterButton(
                icon: '-',
                onTap:
                    _itemCount > 1 ? () => setState(() => _itemCount--) : null,
              ),
              const SizedBox(width: 16),
              Text(
                '$_itemCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              _buildCounterButton(
                icon: '+',
                onTap: () => setState(() => _itemCount++),
              ),
              if (_kycLimitExceeded) const SizedBox(width: 8),
              if (_kycLimitExceeded) _buildVerifyKycButton(),
            ],
          ),
          const SizedBox(height: 8),
          // Summary text
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
              children: [
                TextSpan(
                    text:
                        '$_itemCount x ${_mode == "weight" ? "Rs.${_baseAmount.toInt()}" : "Rs.${_baseAmount.toInt()}"} = Rs.${_amount.toInt()}\n'),
                TextSpan(
                    text:
                        'GST 3%: Rs.${_gst.toStringAsFixed(2)} · Payable: Rs.${_payableNow.toStringAsFixed(2)}\n'),
                TextSpan(text: 'Total: ~ ${_quantity.toStringAsFixed(4)} g'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({required String icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF5E5E5E)),
          color: const Color(0xFF262521),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color:
                  onTap != null ? Colors.white : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyKycButton() {
    return GestureDetector(
      onTap: () => context.go('/kyc-verification'),
      child: AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) => Transform.rotate(
          angle: _wiggleValue * 0.05,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFFF7CD57),
              Color(0xFFE5AF35),
              Color(0xFFB57F23)
            ]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('Verify KYC',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ),
        ),
      ),
    );
  }

  Widget _buildPresets(List<dynamic> presets) {
    return Row(
      children: presets.map((preset) {
        final isSelected = _mode == 'weight'
            ? _weightController.text == preset.toString()
            : _amountController.text == preset.toString();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _onPresetTap(preset),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5E5E5E)
                        : const Color(0xFF4E4E4E),
                  ),
                  color: const Color(0xFF262521),
                ),
                child: Center(
                  child: Text(
                    _mode == 'weight' ? '${preset}g' : 'Rs.${preset}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPayableBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        color: const Color(0xFF19160F),
      ),
      child: Row(
        children: [
          const Text(
            'Payable now (incl. GST)',
            style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFF7CD57), Color(0xFF917833)],
            ).createShader(bounds),
            child: Text(
              'Rs. ${_payableNow.toInt()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: -25,
            top: 0,
            bottom: 0,
            width: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: Colors.white.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 16.5,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: _isSilver
                    ? const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFF999999)])
                    : const LinearGradient(colors: [
                        Color(0xFFF7CD57),
                        Color(0xFFE5AF35),
                        Color(0xFFB57F23)
                      ]),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: _continueToNext,
                  child: Center(
                    child: Text(
                      widget.step == 3 ? 'Proceed to Pay' : 'Continue ->',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isSilver ? Colors.black : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Review Order ─────────────────────────────────────────────────────

  Widget _buildStep2Review() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Step rails
          Row(
            children: [
              Expanded(
                  child: StepRail(
                      label: 'Amount', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(
                  child: StepRail(
                      label: 'Review', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Pay', metalType: _metalType)),
            ],
          ),
          const SizedBox(height: 12),

          // Buying summary circle
          _buildBuyingSummary(),
          const SizedBox(height: 12),

          // Order summary
          _buildOrderSummary(),
          const SizedBox(height: 12),

          // BIS vault info
          _buildBisVaultInfo(),
          const SizedBox(height: 12),

          // Proceed to pay
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildBuyingSummary() {
    final borderColor =
        _isSilver ? const Color(0xFF495C73) : const Color(0xFF3E3522);
    final bgColor =
        _isSilver ? const Color(0xFF1C2633) : const Color(0xFF302715);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Column(
        children: [
          KaratlyCircle(size: 64, metalType: _metalType),
          const SizedBox(height: 12),
          const Text(
            "YOU'RE BUYING",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.12,
              color: Color(0xFF8D8B87),
            ),
          ),
          const SizedBox(height: 8),
          _isSilver || _metalType == 'diamond'
              ? Text(
                  '${_quantity.toStringAsFixed(4)} g',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: _metalType == 'diamond'
                        ? const Color(0xFF4593F9)
                        : Colors.white,
                  ),
                )
              : ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                  ).createShader(bounds),
                  child: Text(
                    '${_quantity.toStringAsFixed(4)} g',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            '24K ${_isSilver ? "Silver" : "Gold"}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8D8B87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final borderColor =
        _isSilver ? const Color(0xFF495C73) : const Color(0xFF444135);
    final bgColor =
        _isSilver ? const Color(0xFF1C2633) : const Color(0xFF191812);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Pre-tax amount', 'Rs.${_amount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('GST (3%)', 'Rs.${_gst.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Buy rate', 'Rs.${_getLiveRate().toInt()}/g'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF33312A))),
            ),
            child: _buildSummaryRow(
              'You get',
              '${_quantity.toStringAsFixed(4)} g',
              isHighlight: true,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Total payable',
            'Rs.${_payableNow.toInt()}',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlight = false}) {
    final valueColor = isHighlight
        ? (_isSilver || _metalType == 'diamond'
            ? (_metalType == 'diamond' ? const Color(0xFF4593F9) : Colors.white)
            : null)
        : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 14 : 13,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
            color: isHighlight ? Colors.white : const Color(0xFF8D8B87),
          ),
        ),
        valueColor != null
            ? Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              )
            : ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                ).createShader(bounds),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlight ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildBisVaultInfo() {
    final bgColor =
        _isSilver ? const Color(0xFF1C2633) : const Color(0xFF211D12);
    final borderColor =
        _isSilver ? const Color(0xFF495C73) : const Color(0xFF3D3A2F);
    final iconBg =
        _isSilver ? const Color(0xFF606B7A) : const Color(0xFF4A3C12);
    final iconColor = _isSilver ? Colors.white : AppTheme.gold;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stored in BIS-certified vault',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your ${_isSilver ? "silver" : "gold"} is 100% insured & redeemable anytime.',
                  style: const TextStyle(
                    fontSize: 10,
                    height: 13 / 10,
                    color: Color(0xFF8D8B87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Payment ──────────────────────────────────────────────────────────

  Widget _buildStep3Payment() {
    final uniqueId = _resolveUniqueId();
    final blockId = ref.read(rateProvider).currentRate?.blockId ?? '';

    if (uniqueId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please login to continue',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            _buildContinueButton(),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Step rails
          Row(
            children: [
              Expanded(
                  child: StepRail(
                      label: 'Amount', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(
                  child: StepRail(
                      label: 'Review', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(
                  child: StepRail(
                      label: 'Pay', active: true, metalType: _metalType)),
            ],
          ),
          const SizedBox(height: 12),

          // Amount summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E2E2E)),
              color: const Color(0xFF19160F),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Payable',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF7E7E7E))),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: _isSilver
                              ? [Colors.white, Colors.white70]
                              : [
                                  const Color(0xFFF7CD57),
                                  const Color(0xFF917833)
                                ],
                        ).createShader(b),
                        child: Text(
                          '₹${_payableNow.toInt()}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Text(
                        '${_quantity.toStringAsFixed(4)} g of ${_isSilver ? "Silver" : "Gold"}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF7E7E7E)),
                      ),
                    ],
                  ),
                ),
                KaratlyCircle(size: 48, metalType: _metalType),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Embedded payment gateway
          EmbeddedPaymentGateway(
            amount: _payableNow,
            metalType: _metalType,
            quantity: _quantity.toStringAsFixed(4),
            lockPrice: _getLiveRate().toStringAsFixed(2),
            blockId: blockId,
            flowType: 'DIGITAL_BUY',
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Processing ───────────────────────────────────────────────────────

  Widget _buildStep4Processing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing your ${_isSilver ? "silver" : "gold"} purchase...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a few moments',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 5: Success ──────────────────────────────────────────────────────────

  Widget _buildStep5Success() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isSilver
                  ? const LinearGradient(
                      colors: [Color(0xFFE8EEF5), Color(0xFF8E9AAA)])
                  : const RadialGradient(
                      center: Alignment(-0.15, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFE27A),
                        Color(0xFFF5BF31),
                        Color(0xFFC98900)
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withOpacity(0.18),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check, size: 60, color: Colors.black),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Purchase Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_quantity.toStringAsFixed(4)} g of ${_isSilver ? "silver" : "gold"} added to your locker',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7E7E7E),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppTheme.gold),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () => context.go(AppRoutes.home),
                  child: const Center(
                    child: Text(
                      'Go Home',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
