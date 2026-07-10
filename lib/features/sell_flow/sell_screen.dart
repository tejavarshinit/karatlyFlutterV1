import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/gold_flow_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/unique_id.dart';
import '../shared/step_rail.dart';
import '../shared/rate_card.dart';
import '../shared/karatly_circle.dart';

/// Sell flow screen with 5 steps matching reference SellFlow.tsx
class SellScreen extends ConsumerStatefulWidget {
  final int step;
  final String metalType;

  const SellScreen({super.key, this.step = 1, this.metalType = 'gold'});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  // Flow state
  String _mode = 'weight';
  final TextEditingController _amountController = TextEditingController(text: '');
  final TextEditingController _weightController = TextEditingController(text: '');
  double _holdingsGrams = 0;
  bool _holdingsLoaded = false;

  // Stored values from previous steps (restored from GoldFlowProvider)
  double _storedAmount = 0;
  double _storedGrams = 0;
  double _storedRate = 0;
  double _storedPayout = 0;
  double _storedPlatformFee = 0;
  bool _hasStoredValues = false;

  @override
  void initState() {
    super.initState();
    if (_amountController.text.isEmpty) _amountController.text = '1000';
    if (_weightController.text.isEmpty) _weightController.text = '1';
    _loadHoldings();
    if (widget.step > 1) {
      final sellState = ref.read(goldFlowProvider).sellState;
      if (sellState.amount > 0) {
        _storedAmount = sellState.amount;
        _storedGrams = sellState.grams;
        _storedRate = sellState.rate;
        _storedPayout = sellState.payout;
        _storedPlatformFee = sellState.platformFee;
        _hasStoredValues = true;
      }
    }
  }

  Future<void> _loadHoldings() async {
    try {
      final uniqueId = _resolveUniqueId();
      if (uniqueId.isEmpty) return;
      final api = AugmontApi(ref.read(augmontDioProvider));
      final result = await api.fetchAugmontPassbook(uniqueId);
      if (result['ok'] == true) {
        final passbook = result['passbook'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _holdingsGrams = _isGold
                ? (double.tryParse((passbook['goldGrms'] ?? passbook['goldBalance'] ?? passbook['gold'] ?? '0').toString()) ?? 0)
                : (double.tryParse((passbook['silverGrms'] ?? passbook['silverBalance'] ?? passbook['silver'] ?? '0').toString()) ?? 0);
            _holdingsLoaded = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _holdingsLoaded = true);
    }
  }

  String _resolveUniqueId() {
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = profile['uniqueId']?.toString();
    if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final dob = profile['dateOfBirth']?.toString() ?? '';
      return UniqueIdHelper.buildMobileDobUniqueId(mobileNumber: phone, dateOfBirth: dob);
    }
    return '';
  }

  String get _metalType => widget.metalType;
  bool get _isGold => _metalType == 'gold';
  bool get _isSilver => _metalType == 'silver';

  double _getLiveRate() {
    if (_hasStoredValues && _storedRate > 0) return _storedRate;
    final rateState = ref.read(rateProvider);
    if (_isSilver) {
      return rateState.currentRate?.silver.sellPrice ?? 0;
    }
    return rateState.currentRate?.sellPrice ?? 0;
  }

  double get _quantity {
    if (_hasStoredValues) return _storedGrams;
    final liveRate = _getLiveRate();
    if (_mode == 'weight') {
      return double.tryParse(_weightController.text) ?? 0;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    return liveRate > 0 ? amount / liveRate : 0;
  }

  double get _amount {
    if (_hasStoredValues) return _storedAmount;
    final liveRate = _getLiveRate();
    if (_mode == 'amount') {
      return double.tryParse(_amountController.text) ?? 0;
    }
    return _quantity * liveRate;
  }

  double get _platformFee {
    if (_hasStoredValues) return _storedPlatformFee;
    return _amount * 0.005;
  }

  double get _payout {
    if (_hasStoredValues) return _storedPayout;
    return _amount - _platformFee;
  }

  bool get _insufficientBalance => _quantity > _holdingsGrams && _holdingsLoaded;

  @override
  void dispose() {
    _amountController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onPresetTap(dynamic value) {
    setState(() {
      if (_mode == 'weight') {
        _weightController.text = value.toString();
      } else {
        _amountController.text = value.toString();
      }
    });
  }

  void _continueToNext() {
    final nextStep = widget.step + 1;
    // Save to GoldFlowProvider for cross-step persistence
    ref.read(goldFlowProvider.notifier).updateSellState(
      amount: _amount,
      grams: _quantity,
      rate: _getLiveRate(),
      payout: _payout,
      platformFee: _platformFee,
      metalType: _metalType,
    );
    if (nextStep <= 5) {
      context.go('/sell/sell/$nextStep?metal=$_metalType');
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _goBack() {
    if (widget.step > 1) {
      context.go('/sell/sell/${widget.step - 1}');
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
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.86,
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
                  children: [
                    _buildDragHandle(),
                    _buildHeader(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildStepContent()),
                  ],
                ),
              ),
            ],
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
      1: 'Sell ${_isSilver ? "Silver" : "Gold"}',
      2: 'Review Sale',
      3: 'Select Bank',
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
        return _buildStep3Bank();
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
    final presets = _mode == 'weight'
        ? [0.5, 1.0, 2.0, _holdingsGrams]
        : [5000, 10000, 25000, 50000];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Step rails
          Row(
            children: [
              Expanded(child: StepRail(label: 'Amount', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Review', metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Pay', metalType: _metalType)),
            ],
          ),
          const SizedBox(height: 8),

          // Holdings card
          _buildHoldingsCard(),
          const SizedBox(height: 8),

          // Live sell rate
          RateCard(
            label: _isGold ? 'Live Sell Rate' : 'Live Sell Rate',
            rateText: 'Rs.${_getLiveRate().toInt().toString()}/g',
            subtitle: 'Live - from Augmont',
            metalType: _metalType,
          ),
          const SizedBox(height: 8),

          // Amount/Weight toggle
          _buildModeToggle(),
          const SizedBox(height: 8),

          // Input
          _buildSellInput(),
          const SizedBox(height: 8),

          // Presets
          _buildPresets(presets),
          const SizedBox(height: 12),

          // Insufficient balance warning
          if (_insufficientBalance) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0x0DFF6B4A),
                border: Border.all(color: const Color(0x33FF6B4A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFFF6B4A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Insufficient balance. You can sell up to your available holdings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B4A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // You'll receive bar
          _buildReceiveBar(),
          const SizedBox(height: 8),

          // Continue button
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildHoldingsCard() {
    final borderColor = _isSilver
        ? Colors.white
        : const Color(0xFFE8B438);

    final cardBg = _isSilver
        ? const LinearGradient(
            begin: Alignment(2.45, 0.38),
            end: Alignment(-0.45, 0.55),
            colors: [Color(0xFF495C73), Color(0xFF0D1117)],
          )
        : const LinearGradient(
            begin: Alignment(2.45, 0.38),
            end: Alignment(-0.45, 0.55),
            colors: [Color(0xFF6C5123), Color(0xFF1E2A28)],
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        gradient: cardBg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR HOLDINGS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: Color(0xFFA1A1A1),
                  ),
                ),
                const SizedBox(height: 4),
                _isSilver || _metalType == 'diamond'
                    ? Text(
                        '${_holdingsGrams.toStringAsFixed(4)} g',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                        ).createShader(bounds),
                        child: Text(
                          '${_holdingsGrams.toStringAsFixed(4)} g',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  '≈ Rs.${(_holdingsGrams * _getLiveRate()).toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA1A1A1),
                  ),
                ),
              ],
            ),
          ),
          KaratlyCircle(size: 60, metalType: _metalType),
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
              left: _mode == 'weight' ? 0 : null,
              right: _mode == 'amount' ? 0 : null,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.44,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: _isSilver
                      ? const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFB8B8B8), Color(0xFF8A8A8A)])
                      : const LinearGradient(
                          colors: [Color(0xFFF7CD57), Color(0xFFDCA520), Color(0xFFC49012)]),
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
                    onTap: () => setState(() => _mode = 'weight'),
                    child: Center(
                      child: Text(
                        'Weight (g)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mode == 'weight' ? FontWeight.w600 : FontWeight.w500,
                          color: _mode == 'weight'
                              ? const Color(0xFF1A1710)
                              : const Color(0xFF8A8578),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'amount'),
                    child: Center(
                      child: Text(
                        'Amount (Rs.)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mode == 'amount' ? FontWeight.w600 : FontWeight.w500,
                          color: _mode == 'amount'
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

  Widget _buildSellInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E4E4E)),
        color: const Color(0xFF21211A),
      ),
      child: Column(
        children: [
          Text(
            _mode == 'weight' ? 'WEIGHT TO SELL' : 'AMOUNT TO SELL',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF5E5E5E)),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      onChanged: (_) => setState(() {}),
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
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
              children: [
                TextSpan(text: 'Rate: Rs.${_getLiveRate().toInt()}/g\n'),
                TextSpan(text: 'Quantity: ${_quantity.toStringAsFixed(4)} g'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(List<dynamic> presets) {
    return Row(
      children: presets.map((preset) {
        final isSelected = _mode == 'weight'
            ? _weightController.text == preset.toString()
            : _amountController.text == preset.toString();
        final label = preset == _holdingsGrams && _mode == 'weight'
            ? 'Max'
            : _mode == 'weight'
                ? '${preset}g'
                : 'Rs.${(preset as num).toInt()}';
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
                    color: isSelected ? const Color(0xFF5E5E5E) : const Color(0xFF4E4E4E),
                  ),
                  color: const Color(0xFF262521),
                ),
                child: Center(
                  child: Text(
                    label,
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

  Widget _buildReceiveBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        color: const Color(0xFF19160F),
      ),
      child: Row(
        children: [
          const Text(
            "You'll Receive",
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
          ),
          const Spacer(),
          _isSilver || _metalType == 'diamond'
              ? Text(
                  'Rs. ${_payout.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              : ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                  ).createShader(bounds),
                  child: Text(
                    'Rs. ${_payout.toInt()}',
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
                    : const LinearGradient(
                        colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)]),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: _insufficientBalance ? null : _continueToNext,
                  child: Center(
                    child: Text(
                      _insufficientBalance ? 'Insufficient Balance' : 'Continue ->',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _insufficientBalance
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black,
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

  // ─── Step 2: Review Sale ─────────────────────────────────────────────────────

  Widget _buildStep2Review() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: StepRail(label: 'Amount', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Review', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Pay', metalType: _metalType)),
            ],
          ),
          const SizedBox(height: 12),

          // Selling summary
          _buildSellingSummary(),
          const SizedBox(height: 12),

          // Sale summary
          _buildSaleSummary(),
          const SizedBox(height: 12),

          // Settled in seconds
          _buildSettledInfo(),
          const SizedBox(height: 12),

          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildSellingSummary() {
    final borderColor = _isSilver
        ? const Color(0xFF495C73)
        : const Color(0xFF3E3522);
    final bgColor = _isSilver
        ? const Color(0xFF1C2633)
        : const Color(0xFF302715);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Column(
        children: [
          KaratlyCircle(size: 60, metalType: _metalType),
          const SizedBox(height: 12),
          const Text(
            "YOU'RE SELLING",
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
                    fontSize: 32,
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
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSaleSummary() {
    final borderColor = _isSilver
        ? const Color(0xFF495C73)
        : const Color(0xFF444135);
    final bgColor = _isSilver
        ? const Color(0xFF1C2633)
        : const Color(0xFF191812);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Column(
        children: [
          _buildSummaryRow('Sell rate', 'Rs.${_getLiveRate().toInt()}/g'),
          const SizedBox(height: 8),
          _buildSummaryRow('Quantity', '${_quantity.toStringAsFixed(4)} g'),
          const SizedBox(height: 8),
          _buildSummaryRow('Subtotal', 'Rs.${_amount.toInt()}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Platform fee (0.5%)', '-Rs.${_platformFee.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF33312A))),
            ),
            child: _buildSummaryRow(
              'Payout',
              'Rs.${_payout.toInt()}',
              isHighlight: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
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

  Widget _buildSettledInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3A2F)),
        color: const Color(0xFF211D12),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, size: 20, color: Color(0xFF15EE01)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settled in Seconds',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Instant payout to your linked bank account',
                  style: TextStyle(
                    fontSize: 10,
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

  // ─── Step 3: Bank Selection ──────────────────────────────────────────────────

  Widget _buildStep3Bank() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: StepRail(label: 'Amount', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Review', active: true, metalType: _metalType)),
              const SizedBox(width: 12),
              Expanded(child: StepRail(label: 'Pay', active: true, metalType: _metalType)),
            ],
          ),
          const SizedBox(height: 8),

          // Payout amount card
          RateCardCompact(
            label: 'PAYOUT AMOUNT',
            value: 'Rs.${_payout.toInt()}',
            badge: 'Instant',
            metalType: _metalType,
          ),
          const SizedBox(height: 16),

          // Bank account card
          _buildBankCard(),
          const SizedBox(height: 12),

          // Security info
          _buildSecurityInfo(),
          const SizedBox(height: 12),

          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildBankCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        color: const Color(0xFF19160F),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF252218),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'State Bank of India',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'XXXX XXXX 1234',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7E7E7E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF1A301E),
            ),
            child: const Text(
              'Primary',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15EE01),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3A2F)),
        color: const Color(0xFF211D12),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock, size: 16, color: Color(0xFF7E7E7E)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified beneficiary · Encrypted with 256-bit SSL',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF7E7E7E),
              ),
            ),
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
            'Processing your ${_isSilver ? "silver" : "gold"} sale...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Instant payout is being processed',
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
                      colors: [Color(0xFFFFE27A), Color(0xFFF5BF31), Color(0xFFC98900)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check, size: 60, color: Colors.black),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sell Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs.${_payout.toInt()} will be credited to your bank account',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7E7E7E),
            ),
          ),
          const SizedBox(height: 24),

          // Transaction details
          _buildTransactionDetails(),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: SizedBox(
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: _isSilver
                          ? const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFF999999)])
                          : const LinearGradient(
                              colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => context.go('/sell/sell/1'),
                        child: const Center(
                          child: Text(
                            'Sell more ->',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        color: const Color(0xFF19160F),
      ),
      child: Column(
        children: [
          _buildDetailRow('Sold', '${_quantity.toStringAsFixed(4)} g'),
          _buildDetailRow('Rate', 'Rs.${_getLiveRate().toInt()}/g'),
          _buildDetailRow('Amount', 'Rs.${_amount.toInt()}'),
          _buildDetailRow('Platform fee', '-Rs.${_platformFee.toStringAsFixed(2)}'),
          _buildDetailRow('Payout', 'Rs.${_payout.toInt()}', isHighlight: true),
          const Divider(color: Color(0xFF2E2D2A), height: 16),
          _buildDetailRow('Order ID', '#SLD${DateTime.now().millisecondsSinceEpoch % 100000}'),
          _buildDetailRow('Status', 'Completed', statusColor: AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7E7E7E),
            ),
          ),
          isHighlight && statusColor == null
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF7CD57), Color(0xFF917833)],
                  ).createShader(bounds),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
                    color: statusColor ?? Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}
