import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/models/gold_rate_model.dart';
import '../../core/models/product_model.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/unique_id.dart';
import '../shared/embedded_payment_gateway.dart';
import '../shared/karatly_circle.dart';
import '../shared/step_rail.dart';

class GoldCoinScreen extends ConsumerStatefulWidget {
  final int step;
  final String metalType;

  const GoldCoinScreen({super.key, this.step = 1, this.metalType = 'gold'});

  @override
  ConsumerState<GoldCoinScreen> createState() => _GoldCoinScreenState();
}

class _GoldCoinScreenState extends ConsumerState<GoldCoinScreen> {
  bool _loading = true;
  List<dynamic> _products = [];
  double _rate = 0;

  // Selected product
  String _selectedSku = '';
  String _selectedName = '';
  String _selectedWeight = '';
  String _selectedPurity = '999';
  double _selectedBasePrice = 0;

  // Address flow
  Map<String, dynamic>? _aadhaarAddress;
  String _providerAddressId = '';
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _addressLoading = false;
  String _addressError = '';

  // Custom address form
  bool _showCustomAddress = false;
  final _addrController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  bool _submittingAddress = false;

  // Payment
  String _paymentAddressId = '';
  bool _showKycPrompt = false;

  bool get _isSilver => widget.metalType == 'silver';

  @override
  void initState() {
    super.initState();
    if (widget.step == 1) _loadProducts();
    if (widget.step >= 2) _restoreState();
  }

  @override
  void dispose() {
    _addrController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  String _resolveUniqueId() {
    final stored = LocalStorageService.getUserUniqueId();
    if (stored != null && stored.isNotEmpty) return stored;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uid = profile['uniqueId']?.toString();
    if (uid != null && uid.isNotEmpty) return uid;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final dob = profile['dateOfBirth']?.toString() ?? '';
      return UniqueIdHelper.buildMobileDobUniqueId(mobileNumber: phone, dateOfBirth: dob);
    }
    return '';
  }

  double get _gst => _selectedBasePrice * 0.03;
  double get _totalPayable => _selectedBasePrice + _gst;

  // ─── Step 1: Load Products ───

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final rateRes = await api.fetchLiveGoldRateSnapshot();
      final prodRes = await api.fetchAugmontProducts(1, 24);
      if (mounted) {
        final snapshot = rateRes['snapshot'];
        final rate = snapshot is GoldRate
            ? (_isSilver ? snapshot.silver.buyPrice : snapshot.buyPrice)
            : 0.0;
        List<dynamic> products = [];
        if (prodRes['ok'] == true) {
          final raw = prodRes['products'] as List<dynamic>? ?? [];
          products = raw.where((p) {
            String mt, name, sku, jt;
            if (p is Product) {
              mt = p.metalType.toLowerCase();
              name = p.name.toLowerCase();
              sku = p.sku.toLowerCase();
              jt = p.jewelleryType.toLowerCase();
            } else if (p is Map) {
              mt = (p['metalType']?.toString() ?? '').toLowerCase();
              name = (p['productName']?.toString() ?? p['name']?.toString() ?? '').toLowerCase();
              sku = (p['sku']?.toString() ?? '').toLowerCase();
              jt = (p['jewelleryType']?.toString() ?? '').toLowerCase();
            } else {
              return false;
            }
            final matchesMetal = mt.contains(widget.metalType) || name.contains(widget.metalType) || sku.contains(_isSilver ? 'sc' : 'gc');
            return matchesMetal && (jt.isEmpty || jt.contains('coin'));
          }).toList();
        }
        setState(() { _products = products; _rate = rate; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _restoreState() {
    try {
      final stored = LocalStorageService.getAugmontOrderReferences();
      if (stored != null && stored.isNotEmpty) {
        final ctx = jsonDecode(stored) as Map<String, dynamic>;
        if (ctx['sku'] != null) {
          _selectedSku = ctx['sku']?.toString() ?? '';
          _selectedName = ctx['productName']?.toString() ?? 'Product';
          _selectedBasePrice = double.tryParse(ctx['basePrice']?.toString() ?? '0') ?? 0;
          _selectedWeight = ctx['redeemWeight']?.toString() ?? ctx['productWeight']?.toString() ?? '';
          _selectedPurity = ctx['purity']?.toString() ?? '999';
          _paymentAddressId = ctx['addressId']?.toString() ?? '';
        }
      }
    } catch (_) {}
  }

  // ─── Product Selection → Address Flow ───

  // Helper to extract string field from Product or Map
  String _getStr(dynamic p, String field, [String alt = '']) {
    if (p is Product) {
      switch (field) {
        case 'sku': return p.sku;
        case 'name': case 'productName': return p.name;
        case 'basePrice': return p.basePrice;
        case 'productWeight': return p.productWeight;
        case 'redeemWeight': return p.redeemWeight;
        case 'purity': return p.purity;
        case 'metalType': return p.metalType;
        case 'jewelleryType': return p.jewelleryType;
        default: return alt;
      }
    }
    if (p is Map) return (p[field]?.toString() ?? alt);
    return alt;
  }

  double _getPrice(dynamic p) {
    if (p is Product) return double.tryParse(p.basePrice) ?? 0;
    if (p is Map) return double.tryParse(p['basePrice']?.toString() ?? '0') ?? 0;
    return 0;
  }

  Future<void> _onProductTap(dynamic product) async {
    final authState = ref.read(authProvider);
    if (authState.user?.kycApproved != true) {
      setState(() => _showKycPrompt = true);
      return;
    }

    final sku = _getStr(product, 'sku');
    if (sku.isEmpty) return;
    setState(() {
      _selectedSku = sku;
      _selectedName = _getStr(product, 'productName', _getStr(product, 'name', 'Product'));
      _selectedBasePrice = _getPrice(product);
      _selectedWeight = _getStr(product, 'redeemWeight', _getStr(product, 'productWeight', ''));
      _selectedPurity = _getStr(product, 'purity', '999');
    });

    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    // Balance check
    final weight = double.tryParse(_selectedWeight) ?? 0;
    if (weight > 0) {
      try {
        final api = AugmontApi(ref.read(augmontDioProvider));
        final pb = await api.fetchAugmontPassbook(uniqueId);
        if (pb['ok'] == true) {
          final data = pb['passbook'] as Map<String, dynamic>? ?? {};
          final balance = _isSilver
              ? (double.tryParse((data['silverGrms'] ?? '0').toString()) ?? 0)
              : (double.tryParse((data['goldGrms'] ?? '0').toString()) ?? 0);
          if (balance < weight) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Insufficient balance. You have ${balance.toStringAsFixed(4)}g but need ${weight.toStringAsFixed(2)}g'),
              ));
            }
            return;
          }
        }
      } catch (_) {}
    }

    // Load Aadhaar address + saved addresses
    await _loadAddresses(uniqueId);
    if (mounted) _showAddressSheet();
  }

  Future<void> _loadAddresses(String uniqueId) async {
    setState(() { _addressLoading = true; _addressError = ''; });
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final results = await Future.wait([
        api.fetchAadhaarAddress(uniqueId: uniqueId),
        api.fetchAugmontAddresses(uniqueId),
      ]);
      final aadhaarRes = results[0];
      final addressesRes = results[1];

      List<Map<String, dynamic>> saved = [];
      if (addressesRes['ok'] == true) {
        final addrList = addressesRes['addresses'];
        if (addrList is List) saved = addrList.cast<Map<String, dynamic>>();
      }

      Map<String, dynamic>? aadhaarAddr;
      String providerId = '';
      if (aadhaarRes['ok'] == true) {
        final rawData = aadhaarRes['data'] as Map<String, dynamic>?;
        final payload = rawData?['payload'] as Map<String, dynamic>?;
        final res = payload?['result'] as Map<String, dynamic>?;
        final data = res?['data'] as Map<String, dynamic>? ?? res;
        if (data != null) {
          aadhaarAddr = data;
          providerId = data['providerAddressId']?.toString() ?? '';
        }
      }

      if (mounted) {
        setState(() {
          _aadhaarAddress = aadhaarAddr;
          _providerAddressId = providerId;
          _savedAddresses = saved;
          _addressLoading = false;
          _addressError = aadhaarAddr == null ? 'Aadhaar address unavailable. You can enter a custom address.' : '';
        });
        if (providerId.isNotEmpty && _paymentAddressId.isEmpty) {
          setState(() => _paymentAddressId = providerId);
        }
      }
    } catch (_) {
      if (mounted) setState(() { _addressLoading = false; _addressError = 'Failed to load address'; });
    }
  }

  void _showAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1710),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isSilver ? Colors.white : const Color(0xFFF7CD57))),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _buildAddressForm(ctx))),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm(BuildContext bottomCtx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_addressLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF7CD57))))
        else ...[
          // Aadhaar address
          if (_aadhaarAddress != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E2E2E)),
                color: const Color(0xFF0F1416),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF202326), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, size: 18, color: Color(0xFFF7CD57)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_aadhaarAddress!['name']?.toString() ?? 'Address', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          _aadhaarAddress!['addressLine']?.toString() ?? _aadhaarAddress!['address']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, size: 20, color: _paymentAddressId == _providerAddressId ? const Color(0xFF15EE01) : Colors.grey,),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() { _paymentAddressId = _providerAddressId; _showCustomAddress = false; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _paymentAddressId == _providerAddressId ? const Color(0xFF15EE01) : const Color(0xFF2E2E2E)),
                  color: const Color(0xFF0F1416),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: _providerAddressId,
                      groupValue: _paymentAddressId,
                      onChanged: (v) => setState(() { _paymentAddressId = v!; _showCustomAddress = false; }),
                      fillColor: WidgetStateProperty.all(const Color(0xFFF7CD57)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Use Aadhaar Address', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
          if (_addressError.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF2A1111), borderRadius: BorderRadius.circular(12)),
              child: Text(_addressError, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
            ),
            const SizedBox(height: 12),
          ],
          // Saved addresses
          if (_savedAddresses.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Saved Addresses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            ..._savedAddresses.take(3).map((addr) => _savedAddressTile(addr)),
          ],
          // Custom address toggle
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() { _showCustomAddress = !_showCustomAddress; _paymentAddressId = ''; }),
            child: Row(
              children: [
                Icon(_showCustomAddress ? Icons.expand_less : Icons.add_circle_outline, size: 20, color: const Color(0xFFF7CD57)),
                const SizedBox(width: 8),
                Text('Add Custom Address', style: TextStyle(fontSize: 13, color: const Color(0xFFF7CD57))),
              ],
            ),
          ),
          if (_showCustomAddress) ...[
            const SizedBox(height: 12),
            _buildTextField(_addrController, 'Address', maxLines: 2),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildTextField(_cityController, 'City')),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(_stateController, 'State')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildTextField(_pincodeController, 'Pincode', maxLen: 6)),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(_landmarkController, 'Landmark')),
            ]),
          ],
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 48,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(colors: _isSilver ? [Colors.white, Colors.grey[400]!] : [const Color(0xFFFED45C), const Color(0xFFDB9502)]),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _submittingAddress ? null : () => _confirmAddress(bottomCtx),
                child: Center(
                  child: _submittingAddress
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Confirm & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _savedAddressTile(Map<String, dynamic> addr) {
    final addrId = addr['addressId']?.toString() ?? addr['userAddressId']?.toString() ?? '';
    final isSelected = _paymentAddressId == addrId;
    return GestureDetector(
      onTap: () => setState(() { _paymentAddressId = addrId; _showCustomAddress = false; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF15EE01) : const Color(0xFF2E2E2E)),
          color: const Color(0xFF0F1416),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: addrId,
              groupValue: _paymentAddressId,
              onChanged: (v) => setState(() { _paymentAddressId = v!; _showCustomAddress = false; }),
              fillColor: WidgetStateProperty.all(const Color(0xFFF7CD57)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(addr['name']?.toString() ?? 'Address', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('${addr['address']?.toString() ?? ""}, ${addr['cityName']?.toString() ?? addr['city']?.toString() ?? ""}', style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {int? maxLines, int? maxLen}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
        color: const Color(0xFF24201A),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines ?? 1,
        maxLength: maxLen,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5E5E5E)),
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  Future<void> _confirmAddress(BuildContext bottomCtx) async {
    if (_showCustomAddress) {
      // Validate custom address
      if (_addrController.text.trim().isEmpty || _cityController.text.trim().isEmpty ||
          _stateController.text.trim().isEmpty || _pincodeController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required address fields')));
        return;
      }
      setState(() => _submittingAddress = true);
      try {
        final api = AugmontApi(ref.read(augmontDioProvider));
        final profile = LocalStorageService.getUserProfile() ?? {};
        final result = await api.createAugmontAddress(uniqueId: _resolveUniqueId(), request: {
          'name': profile['fullName']?.toString() ?? '',
          'mobileNumber': profile['mobileNumber']?.toString() ?? '',
          'email': profile['email']?.toString() ?? '',
          'address': _addrController.text.trim(),
          'cityName': _cityController.text.trim(),
          'stateName': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'landmark': _landmarkController.text.trim(),
        });
        if (result['ok'] == true) {
          _paymentAddressId = result['userAddressId']?.toString() ?? '';
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Failed to create address')));
          setState(() => _submittingAddress = false);
          return;
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _submittingAddress = false);
        return;
      }
    } else if (_paymentAddressId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a delivery address')));
      return;
    }

    // Save context and navigate
    await LocalStorageService.setAugmontOrderReferences(jsonEncode({
      'sku': _selectedSku,
      'productName': _selectedName,
      'basePrice': _selectedBasePrice.toString(),
      'redeemWeight': _selectedWeight,
      'purity': _selectedPurity,
      'metalType': widget.metalType,
      'addressId': _paymentAddressId,
    }));

    if (mounted) {
      Navigator.pop(bottomCtx);
      context.go('/sell/gold-coin/review?metal=${widget.metalType}');
    }
  }

  // ─── Navigation ───

  void _goBack() {
    if (widget.step > 1) {
      context.go('/sell/gold-coin/${widget.step - 1}?metal=${widget.metalType}');
    } else {
      context.pop();
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.86),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              gradient: RadialGradient(
                center: const Alignment(0.9755, -0.3792), radius: 1.04,
                colors: [_isSilver ? const Color(0xFF293341) : const Color(0xFF4A3A1E), Colors.black],
              ),
              boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 60, offset: Offset(0, -24))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.02), Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.35)],
                          stops: const [0, 0.18, 1],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: Column(
                      children: [
                        Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFF3E3E3E), borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 16),
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
          _buildKycPrompt(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final titles = <int, String>{1: 'Redeem ${_isSilver ? "Silver" : "Gold"} Coins', 2: 'Payment', 3: 'Processing', 4: 'Success'};
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: GestureDetector(onTap: _goBack, child: const SizedBox(width: 24, height: 24, child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white)))),
          Center(child: Text(titles[widget.step] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
          Positioned(right: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFF3B3935), shape: BoxShape.circle), child: const Icon(Icons.shield, size: 12, color: Color(0xFF15EE01)))),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (widget.step) {
      case 1: return _buildStep1Products();
      case 2: return _buildStep2Review();
      case 3: return _buildStep3Processing();
      case 4: return _buildStep4Success();
      default: return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Product List ───

  Widget _buildStep1Products() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(children: [
            Expanded(child: StepRail(label: 'Select', active: true, metalType: widget.metalType)),
            const SizedBox(width: 12), Expanded(child: StepRail(label: 'Redeem', metalType: widget.metalType)),
            const SizedBox(width: 12), Expanded(child: StepRail(label: 'Done', metalType: widget.metalType)),
          ]),
          const SizedBox(height: 12),
          // Rate card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isSilver ? Colors.white : const Color(0xFFE8B438)),
              gradient: LinearGradient(
                begin: Alignment(2.45, 0.38), end: Alignment(-0.45, 0.55),
                colors: _isSilver ? [const Color(0xFF495C73), const Color(0xFF0D1117)] : [const Color(0xFF6C5123), const Color(0xFF1E2A28)],
              ),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isSilver ? 'Redeem Physical Silver' : 'Redeem Physical Gold', style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1A1))),
                const SizedBox(height: 4),
                Text(_rate > 0 ? '₹${_rate.toInt()}/g' : 'Live rate', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _isSilver ? Colors.white : null)),
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.bolt, size: 12, color: Color(0xFF0EA300)), const SizedBox(width: 4), Text('Live from Augmont', style: const TextStyle(fontSize: 10, color: Color(0xFF0EA300)))]),
              ])),
              KaratlyCircle(size: 60, metalType: widget.metalType),
            ]),
          ),
          const SizedBox(height: 16),
          // KYC banner
          Consumer(builder: (context, ref, _) {
            final authState = ref.watch(authProvider);
            if (authState.user?.kycApproved == true) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => context.go('/kyc-verification'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33FFD700)),
                  gradient: const LinearGradient(colors: [Color(0x26F5BF31), Color(0xCC120D05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), color: Colors.black.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE784), Color(0xFFC88912)]),
                          boxShadow: [BoxShadow(color: Color(0x33F5BF31), blurRadius: 12)]),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF11130F), size: 20)),
                      const SizedBox(width: 16),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('KYC Verification Required', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF7CD57))),
                        SizedBox(height: 4),
                        Text('You can only redeem after KYC verification. Click here to complete your verification instantly.', style: TextStyle(fontSize: 11, color: Color(0xFFB0B0B0))),
                      ])),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFF7CD57)),
                    ]),
                  ),
                ),
              ),
            );
          }),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Choose Coin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _isSilver ? Colors.white : const Color(0xFFF7CD57))),
            if (!_loading) Text('${_products.length} products', style: const TextStyle(fontSize: 10, color: Color(0xFF8D8B87))),
          ]),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF7CD57))))
          else if (_products.isEmpty)
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF1A1408), border: Border.all(color: const Color(0xFF3E3E3E))),
              child: const Center(child: Text('No products available', style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 12))))
          else
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _products.length,
                itemBuilder: (_, i) => _productCard(_products[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productCard(dynamic product) {
    final name = _getStr(product, 'productName', _getStr(product, 'name', 'Product'));
    final sku = _getStr(product, 'sku', '');
    final weight = _getStr(product, 'redeemWeight', _getStr(product, 'productWeight', ''));
    final purity = _getStr(product, 'purity', '999');

    return GestureDetector(
      onTap: () => _onProductTap(product),
      child: Container(
        width: 168, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: _isSilver ? [const Color(0xFF1C2633), const Color(0xFF0D1117)] : [const Color(0xFF241B0D), const Color(0xFF120D05)]),
          border: Border.all(color: _isSilver ? Colors.white.withValues(alpha: 0.19) : const Color(0xFF3E3522)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: _isSilver ? [const Color(0xFFE8EEF5), const Color(0xFF8E9AAA)] : [const Color(0xFFFFE27A), const Color(0xFFC98900)])),
              child: Center(child: Text(_isSilver ? 'Ag' : 'Au', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)))),
            Icon(Icons.arrow_forward_ios, size: 16, color: _isSilver ? Colors.white : const Color(0xFFF7CD57)),
          ]),
          const SizedBox(height: 12),
          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 2),
          Text(sku, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 8),
          _infoRow('Weight', '${weight}g'),
          _infoRow('Purity', purity),
          const SizedBox(height: 8),
          Text('Tap to redeem', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _isSilver ? Colors.white : const Color(0xFFF7CD57))),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  // ─── Step 2: Review + Payment ───

  Widget _buildStep2Review() {
    if (_selectedSku.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Session expired', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 16),
        SizedBox(width: 200, height: 44,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(colors: _isSilver ? [Colors.white, Colors.grey[400]!] : [const Color(0xFFFED45C), const Color(0xFFDB9502)])),
            child: Material(color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(50),
                onTap: () => context.go('/sell/gold-coin/1?metal=${widget.metalType}'),
                child: const Center(child: Text('Select Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)))),
            ),
        ),
          ),
          _buildKycPrompt(),
        ],
      ),
    );
  }

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(children: [
            Expanded(child: StepRail(label: 'Select', active: true, metalType: widget.metalType)),
            const SizedBox(width: 12), Expanded(child: StepRail(label: 'Redeem', active: true, metalType: widget.metalType)),
            const SizedBox(width: 12), Expanded(child: StepRail(label: 'Done', metalType: widget.metalType)),
          ]),
          const SizedBox(height: 12),
          // Total payable
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isSilver ? Colors.white.withValues(alpha: 0.19) : const Color(0xFFE8B438).withValues(alpha: 0.25)),
              gradient: LinearGradient(begin: Alignment(2.45, 0.38), end: Alignment(-0.45, 0.55),
                colors: _isSilver ? [const Color(0xFF495C73), const Color(0xFF0D1117)] : [const Color(0xFF6C5123), const Color(0xFF1E2A28)]),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Payable (incl. GST)', style: TextStyle(fontSize: 11, color: Color(0xFFA1A1A1))),
                const SizedBox(height: 4),
                Text('₹${_totalPayable.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _isSilver ? Colors.white : null)),
              ]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1A301E), borderRadius: BorderRadius.circular(30)),
                child: const Text('Secure', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF15EE01)))),
            ]),
          ),
          const SizedBox(height: 12),
          // Product details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isSilver ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF3E3522)),
              color: _isSilver ? const Color(0xFF1C2633) : const Color(0xFF191812),
            ),
            child: Column(children: [
              _detailRow('Product', _selectedName), _detailRow('SKU', _selectedSku),
              _detailRow('Weight', '${_selectedWeight}g'), _detailRow('Purity', _selectedPurity),
              const Divider(color: Color(0xFF33312A), height: 20),
              _detailRow('Base price', '₹${_selectedBasePrice.toStringAsFixed(2)}'),
              _detailRow('GST (3%)', '₹${_gst.toStringAsFixed(2)}'),
              const Divider(color: Color(0xFF33312A), height: 20),
              _detailRow('Total payable', '₹${_totalPayable.toStringAsFixed(2)}', bold: true),
            ]),
          ),
          const SizedBox(height: 16),
          // Address used
          if (_paymentAddressId.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E2E2E)), color: const Color(0xFF0F1416),
              ),
              child: Row(children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF15EE01)),
                const SizedBox(width: 8),
                const Text('Delivery address confirmed', style: TextStyle(fontSize: 12, color: Color(0xFF15EE01))),
              ]),
            ),
          // Embedded payment gateway with addressId
          EmbeddedPaymentGateway(
            amount: _totalPayable,
            metalType: widget.metalType,
            quantity: '1',
            lockPrice: _selectedBasePrice.toStringAsFixed(2),
            flowType: 'PHYSICAL_REDEMPTION',
            sku: _selectedSku.isNotEmpty ? _selectedSku : null,
            addressId: _paymentAddressId.isNotEmpty ? _paymentAddressId : null,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: bold ? Colors.white : const Color(0xFF8D8B87), fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: bold ? (_isSilver ? Colors.white : const Color(0xFFF7CD57)) : Colors.white)),
      ]),
    );
  }

  // ─── Step 3: Processing ───

  Widget _buildStep3Processing() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF7CD57)))),
      const SizedBox(height: 24),
      Text('Processing your ${_isSilver ? "silver" : "gold"} redemption...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
      const SizedBox(height: 8),
      const Text('This may take a few moments', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
    ]));
  }

  // ─── Step 4: Success ───

  Widget _buildStep4Success() {
    Map<String, dynamic>? redeemResult;
    try {
      final raw = LocalStorageService.getRedeemResult();
      if (raw != null && raw.isNotEmpty) {
        redeemResult = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}
    final result = redeemResult;

    return SingleChildScrollView(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 20),
        Container(width: 130, height: 130,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: _isSilver ? const LinearGradient(colors: [Color(0xFFE8EEF5), Color(0xFF8E9AAA)]) : const RadialGradient(center: Alignment(-0.15, -0.2), radius: 1.2, colors: [Color(0xFFFFE27A), Color(0xFFF5BF31), Color(0xFFC98900)]),
            boxShadow: [BoxShadow(color: const Color(0xFFF7CD57).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 10)]),
          child: const Center(child: Icon(Icons.check, size: 60, color: Colors.black))),
        const SizedBox(height: 24),
        const Text('Redeem Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Your ${_isSilver ? "silver" : "gold"} coin will be delivered to your address', style: const TextStyle(fontSize: 14, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 24),
        if (result != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2E2E2E)), color: const Color(0xFF19160F)),
            child: Column(children: [
              if (result['productName'] != null)
                _detailRow('Product', result['productName'].toString()),
              if (result['sku'] != null)
                _detailRow('SKU', result['sku'].toString()),
              if (result['weight'] != null)
                _detailRow('Weight', '${result['weight']}g'),
              if (result['orderId'] != null || result['sabbpeOrderId'] != null)
                _detailRow('Order ID', '#${(result['orderId'] ?? result['sabbpeOrderId']).toString()}'),
              if (result['message'] != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(result['message'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)))),
            ]),
          ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 44,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(colors: _isSilver ? [Colors.white, Colors.grey[400]!] : [const Color(0xFFFED45C), const Color(0xFFDB9502)])),
            child: Material(color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(50),
                onTap: () => context.replace(AppRoutes.home),
                child: const Center(child: Text('Go Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)))),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]      ),
    );
  }

  // ─── KYC Prompt Modal ───

  Widget _buildKycPrompt() {
    if (!_showKycPrompt) return const SizedBox.shrink();
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.7)),
        Center(
          child: Container(
            width: 358, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0x4DF7CD57)),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF503B15), Color(0xFF1C1408), Color(0xFF080603)]),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(alignment: Alignment.topRight, child: GestureDetector(
                onTap: () => setState(() => _showKycPrompt = false),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.white70)),
              )),
              Container(width: 56, height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE784), Color(0xFFC88912)])),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF11130F), size: 23)),
              const SizedBox(height: 16),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF7CD57))),
                const SizedBox(width: 6),
                const Text('KYC REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: Color(0xFFF7CD57))),
              ]),
              const SizedBox(height: 8),
              const Text('KYC Verification Required', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('You need to complete KYC verification before you can redeem physical products.', style: TextStyle(fontSize: 12, color: Color(0xFFB8B4AD)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () { setState(() => _showKycPrompt = false); context.go('/kyc-verification'); },
                child: Container(width: double.infinity, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)])),
                  child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Complete KYC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                  ])),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showKycPrompt = false),
                child: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.white54)),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
