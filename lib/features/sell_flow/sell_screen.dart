import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/augmont_api.dart';
import '../../core/api/config.dart';
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

  // Bank selection state
  List<Map<String, dynamic>> _banks = [];
  bool _banksLoading = false;
  Map<String, dynamic>? _selectedBank;
  String? _bankError;
  bool _orderExecuted = false;

  @override
  void initState() {
    super.initState();
    if (_amountController.text.isEmpty) _amountController.text = '1000';
    if (_weightController.text.isEmpty) _weightController.text = '1';
    _loadHoldings();
    if (widget.step == 3) _loadPrimaryBank();
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

  String _extractBankId(Map<String, dynamic> bank) {
    final raw =
      (bank['provider_bank_id']?.toString() ??
          bank['userBankId']?.toString() ??
          bank['bankId']?.toString() ??
          bank['id']?.toString() ??
          '').trim();
    return raw.replaceAll(RegExp(r'[()]'), '');
  }

  Map<String, dynamic>? _normalizeBankRecord(Map<String, dynamic>? bank) {
    if (bank == null) return null;

    final bankId = _extractBankId(bank);
    final bankName = (bank['bankName'] ?? bank['bank_name'] ?? bank['bank'] ?? '').toString().trim();
    final accountNumber = (bank['accountNumber'] ?? bank['account_number'] ?? bank['bankNumber'] ?? bank['bank_number'] ?? '').toString().trim();
    final accountType = (bank['accountType'] ?? bank['account_type'] ?? 'Savings').toString().trim();
    final ifsc = (bank['ifscCode'] ?? bank['ifsc_code'] ?? bank['ifsc'] ?? '').toString().trim().toUpperCase();
    final isPrimary = bank['isPrimary'] == true || bank['is_primary'] == true;

    return <String, dynamic>{
      ...bank,
      if (bankId.isNotEmpty) 'userBankId': bankId,
      if (bankId.isNotEmpty) 'provider_bank_id': bankId,
      if (bankName.isNotEmpty) 'bankName': bankName,
      if (bankName.isNotEmpty) 'bank_name': bankName,
      if (bankName.isNotEmpty) 'bank': bankName,
      if (accountNumber.isNotEmpty) 'accountNumber': accountNumber,
      if (accountNumber.isNotEmpty) 'account_number': accountNumber,
      if (accountType.isNotEmpty) 'accountType': accountType,
      if (accountType.isNotEmpty) 'account_type': accountType,
      if (ifsc.isNotEmpty) 'ifscCode': ifsc,
      if (ifsc.isNotEmpty) 'ifsc_code': ifsc,
      if (ifsc.isNotEmpty) 'ifsc': ifsc,
      'isPrimary': isPrimary,
      'is_primary': isPrimary,
    };
  }

  Map<String, dynamic>? _readStoredPrimaryBank() {
    try {
      final rawBank = LocalStorageService.getPrimaryBank();
      if (rawBank == null || rawBank.isEmpty) return null;
      final decoded = jsonDecode(rawBank);
      if (decoded is Map) {
        return _normalizeBankRecord(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _storePrimaryBank(Map<String, dynamic> bank) async {
    final normalized = _normalizeBankRecord(bank);
    if (normalized == null) return;
    final bankId = _extractBankId(normalized);
    if (bankId.isNotEmpty) {
      await LocalStorageService.setPrimaryBankId(bankId);
    }
    await LocalStorageService.setPrimaryBank(jsonEncode(normalized));
  }

  String _maskAccount(String accountNumber) {
    final cleaned = accountNumber.replaceAll(' ', '');
    if (cleaned.length <= 4) return '****$cleaned';
    return '****${cleaned.substring(cleaned.length - 4)}';
  }

  Future<void> _loadPrimaryBank() async {
    final profile = LocalStorageService.getUserProfile();
    final uniqueId = profile?['uniqueId']?.toString() ?? '';
    if (uniqueId.isEmpty) {
      if (mounted) {
        setState(() {
          _banksLoading = false;
          _bankError = 'User session not found.';
        });
      }
      return;
    }
    setState(() {
      _banksLoading = true;
      _bankError = null;
    });
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      // Call all three APIs in parallel like React
      final results = await Future.wait([
        api.fetchAugmontUserBanks(uniqueId),
        api.fetchAugmontPrimaryUserBank(uniqueId: uniqueId),
      ]);
      final listRes = results[0];
      final primaryRes = results[1];

      // 1. Parse all banks from list
      final allBanks = (listRes['ok'] == true)
          ? (listRes['banks'] as List<dynamic>?)
              ?.map((b) => Map<String, dynamic>.from(b as Map))
              .toList() ?? []
          : <Map<String, dynamic>>[];

      // 2. Try primary bank from primary API
      Map<String, dynamic>? selectedBank;
      if (primaryRes['ok'] == true && primaryRes['bank'] != null) {
        selectedBank = _normalizeBankRecord(Map<String, dynamic>.from(primaryRes['bank'] as Map));
      } else if (primaryRes['ok'] == true && primaryRes['banks'] != null) {
        final banks = primaryRes['banks'] as List<dynamic>;
        if (banks.isNotEmpty) {
          selectedBank = _normalizeBankRecord(Map<String, dynamic>.from(banks.first as Map));
        }
      }

      // 3. If no primary found, find from list
      if (selectedBank == null && allBanks.isNotEmpty) {
        final primaryBank = allBanks.where((b) => b['isPrimary'] == true || b['is_primary'] == true).toList();
        if (primaryBank.isNotEmpty) {
          selectedBank = _normalizeBankRecord(primaryBank.first);
        } else if (allBanks.length == 1) {
          selectedBank = _normalizeBankRecord(allBanks.first);
          final singleId = _extractBankId(allBanks.first);
          if (singleId.isNotEmpty) {
            await api.setPrimaryAugmontUserBank(uniqueId: uniqueId, userBankId: singleId);
          }
        }
      }

      if (selectedBank == null) {
        selectedBank = _readStoredPrimaryBank();
      }

      if (selectedBank != null) {
        final bankId = _extractBankId(selectedBank);
        final bankName = (selectedBank['bankName'] ?? selectedBank['bank_name'] ?? selectedBank['bank'] ?? '').toString().trim();
        await _storePrimaryBank(selectedBank);
        if (mounted) {
          ref.read(goldFlowProvider.notifier).updateSellState(
            uniqueId: uniqueId,
            userBankId: bankId.isNotEmpty ? bankId : null,
            bankName: bankName.isNotEmpty ? bankName : null,
          );
        }
      }

      if (mounted) {
        setState(() {
          _selectedBank = selectedBank;
          _banks = allBanks.map((b) => _normalizeBankRecord(b) ?? b).toList();
          _bankError = selectedBank == null ? 'No primary bank found.' : null;
          _banksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _bankError = 'Could not load bank details.'; _banksLoading = false; });
    }
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
    final resolvedBank = _selectedBank ?? _readStoredPrimaryBank();
    final resolvedBankId = resolvedBank != null ? _extractBankId(resolvedBank) : '';
    final resolvedBankName = resolvedBank != null
        ? (resolvedBank['bankName'] ?? resolvedBank['bank_name'] ?? resolvedBank['bank'] ?? '').toString().trim()
        : '';
    ref.read(goldFlowProvider.notifier).updateSellState(
      amount: _amount,
      grams: _quantity,
      rate: _getLiveRate(),
      payout: _payout,
      platformFee: _platformFee,
      metalType: _metalType,
      uniqueId: _resolveUniqueId(),
      userBankId: resolvedBankId.isNotEmpty ? resolvedBankId : null,
      bankName: resolvedBankName.isNotEmpty ? resolvedBankName : null,
    );
    if (nextStep <= 5) {
      context.go('/sell/sell/$nextStep?metal=$_metalType');
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _goBack() {
    if (widget.step == 5) {
      context.go(AppRoutes.home);
    } else if (widget.step > 1) {
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
        borderRadius: BorderRadius.circular(10),
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
          _banksLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                ))
              : _selectedBank != null
                  ? _buildBankCard(_selectedBank!)
                  : _buildNoBankCard(),
          if (_bankError != null && _selectedBank == null) ...[
            const SizedBox(height: 8),
            Text(_bankError!, style: const TextStyle(fontSize: 12, color: Color(0xFFFF4D4D))),
          ],
          const SizedBox(height: 12),

          // Security info
          _buildSecurityInfo(),
          const SizedBox(height: 12),

          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank) {
    final normalized = _normalizeBankRecord(bank) ?? bank;
    final isPrimary = normalized['isPrimary'] == true || normalized['is_primary'] == true;
    final accountNumber = (normalized['accountNumber'] ?? normalized['account_number'] ?? '').toString();
    final bankName = (normalized['bankName'] ?? normalized['bank_name'] ?? normalized['bank'] ?? 'Bank').toString();
    final accountType = (normalized['accountType'] ?? normalized['account_type'] ?? 'Savings').toString();
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF252218),
            ),
            child: const Icon(Icons.account_balance, color: AppTheme.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$bankName ${_maskAccount(accountNumber)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF263938),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF6DD6FF)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$accountType · IMPS Instant',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBankCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        color: const Color(0xFF19160F),
      ),
      child: Column(
        children: [
          const Text('No primary bank found.', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go(AppRoutes.paymentMethods),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _isSilver
                    ? const LinearGradient(colors: [Colors.white, Color(0xFF999999)])
                    : const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)]),
              ),
              child: const Center(child: Text('+ Add Bank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black))),
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
    // Auto-execute sell order on first render
    WidgetsBinding.instance.addPostFrameCallback((_) => _executeSellOrder());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold))),
          const SizedBox(height: 24),
          Text('Processing your ${_isSilver ? "silver" : "gold"} sale...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Instant payout is being processed', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
        ],
      ),
    );
  }

  Future<void> _executeSellOrder() async {
    if (_orderExecuted) return;
    _orderExecuted = true;
    final sellState = ref.read(goldFlowProvider).sellState;
    final uniqueId = sellState.uniqueId.isNotEmpty ? sellState.uniqueId : _resolveUniqueId();
    final resolvedBank = _selectedBank ?? _readStoredPrimaryBank();
    final userBankId = sellState.userBankId.isNotEmpty
        ? sellState.userBankId
        : (resolvedBank != null ? _extractBankId(resolvedBank) : '');
    final grams = sellState.grams;
    if (uniqueId.isEmpty || userBankId.isEmpty || grams <= 0) {
      if (mounted) context.go('/sell/sell/${widget.step - 1}?metal=$_metalType');
      return;
    }
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final res = await api.createAugmontSellOrder(
        merchantId: ApiConfig.defaultMerchantId,
        request: {
          'metalType': _metalType,
          'quantity': grams.toStringAsFixed(4),
          'uniqueId': uniqueId,
          'userBankId': userBankId,
        },
      );
      if (res['ok'] == true) {
        ref.read(goldFlowProvider.notifier).updateSellState(
          transactionId: res['data']?['transactionId']?.toString(),
          merchantTransactionId: res['data']?['merchantTransactionId']?.toString(),
          orderStatus: 'completed',
        );
        if (mounted) context.go('/sell/sell/5?metal=$_metalType');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Sell order failed')));
          context.go('/sell/sell/3?metal=$_metalType');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to process sell order')));
        context.go('/sell/sell/3?metal=$_metalType');
      }
    }
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
    final sellState = ref.read(goldFlowProvider).sellState;
    final orderId = sellState.transactionId?.isNotEmpty == true
        ? sellState.transactionId!
        : sellState.merchantTransactionId?.isNotEmpty == true
            ? sellState.merchantTransactionId!
            : '#SLD${DateTime.now().millisecondsSinceEpoch % 100000}';
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
          _buildDetailRow('Order ID', orderId),
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
