import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/cashfree_api.dart';
import '../../../core/services/rate_provider.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/storage/local_storage.dart';
import '../../payment/payment_redirect.dart';

class DiamondPaymentGateway extends ConsumerStatefulWidget {
  final double amount;
  final List<Map<String, dynamic>> items;
  final VoidCallback onPaymentStarted;
  final VoidCallback? onPaymentError;

  const DiamondPaymentGateway({
    super.key,
    required this.amount,
    required this.items,
    required this.onPaymentStarted,
    this.onPaymentError,
  });

  @override
  ConsumerState<DiamondPaymentGateway> createState() => _DiamondPaymentGatewayState();
}

class _DiamondPaymentGatewayState extends ConsumerState<DiamondPaymentGateway> {
  String _selectedMethod = 'upi';
  bool _loading = false;
  String _error = '';

  // UPI
  final _vpaController = TextEditingController();
  bool _showQr = false;
  String _qrData = '';
  String _upiMessage = '';
  Timer? _upiPollTimer;
  // Net Banking
  final _bankSearchController = TextEditingController();
  String _selectedBankCode = '';

  // Cards
  String _cardType = 'CREDIT_CARD';
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryMmController = TextEditingController();
  final _cardExpiryYyController = TextEditingController();
  final _cardCvvController = TextEditingController();

  static const _banks = [
    {'code': '3021', 'name': 'HDFC Bank'},
    {'code': '3022', 'name': 'ICICI Bank'},
    {'code': '3003', 'name': 'Axis Bank'},
    {'code': '3044', 'name': 'SBI'},
    {'code': '3020', 'name': 'Federal Bank'},
    {'code': '3032', 'name': 'Kotak Bank'},
    {'code': '3009', 'name': 'Canara Bank'},
    {'code': '3055', 'name': 'Union Bank'},
    {'code': '3058', 'name': 'Yes Bank'},
  ];

  static const _mobileApps = [
    {'type': 'APP', 'provider': 'phonepe', 'name': 'PhonePe', 'icon': Icons.phone_android},
    {'type': 'APP', 'provider': 'amazonpay', 'name': 'Amazon Pay', 'icon': Icons.shopping_cart},
    {'type': 'APP', 'provider': 'jio', 'name': 'Jio', 'icon': Icons.wifi},
    {'type': 'APP', 'provider': 'ola', 'name': 'Ola', 'icon': Icons.directions_car},
    {'type': 'APP', 'provider': 'mobikwik', 'name': 'Mobikwik', 'icon': Icons.account_balance_wallet},
    {'type': 'APP', 'provider': 'airtel', 'name': 'Airtel', 'icon': Icons.signal_cellular_alt},
    {'type': 'APP', 'provider': 'freecharge', 'name': 'Freecharge', 'icon': Icons.receipt_long},
    {'type': 'APP', 'provider': 'test', 'name': 'Test', 'icon': Icons.science},
  ];

  static const Color _primary = Color(0xFF0084FF);
  static const Color _accent = Color(0xFF3AC7FF);
  static const Color _cardBorder = Color(0xFF2E2E2E);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _upiPollTimer?.cancel();
    _vpaController.dispose();
    _bankSearchController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryMmController.dispose();
    _cardExpiryYyController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  String get _clientId => LocalStorageService.getDiamondClientId() ?? '';

  CashfreeApi _cashfreeApi() {
    final dio = ref.read(augmontDioProvider);
    return CashfreeApi(dio);
  }

  Map<String, dynamic> _buildPaymentPayload() {
    switch (_selectedMethod) {
      case 'upi':
        if (_showQr) return {'type': 'UPI_QR'};
        return {'type': 'UPI_COLLECT', 'vpa': _vpaController.text.trim()};
      case 'mobile':
        return {'type': 'APP', 'provider': 'phonepe'};
      case 'netbanking':
        return {'type': 'NET_BANKING', 'bankCode': _selectedBankCode};
      case 'cards':
        return {
          'type': 'CARD',
          'cardType': _cardType,
          'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
          'cardHolderName': _cardHolderController.text.trim(),
          'cardExpiryMm': _cardExpiryMmController.text.trim(),
          'cardExpiryYy': _cardExpiryYyController.text.trim(),
          'cardCvv': _cardCvvController.text.trim(),
        };
      default:
        return {'type': 'NET_BANKING', 'bankCode': '3021'};
    }
  }

  Future<void> _initiatePayment() async {
    if (_selectedMethod == 'netbanking' && _selectedBankCode.isEmpty) {
      setState(() => _error = 'Please select a bank');
      return;
    }
    if (_selectedMethod == 'upi' && !_showQr && _vpaController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a UPA VPA');
      return;
    }
    if (_selectedMethod == 'cards') {
      if (_cardNumberController.text.trim().length < 16) {
        setState(() => _error = 'Please enter a valid card number');
        return;
      }
      if (_cardHolderController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter card holder name');
        return;
      }
      if (_cardExpiryMmController.text.trim().length < 2 || _cardExpiryYyController.text.trim().length < 2) {
        setState(() => _error = 'Please enter expiry date');
        return;
      }
      if (_cardCvvController.text.trim().length < 3) {
        setState(() => _error = 'Please enter CVV');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final api = _cashfreeApi();
      final response = await api.createDiamondPayment(
        clientId: _clientId,
        totalAmount: widget.amount,
        items: widget.items,
        payment: _buildPaymentPayload(),
      );

      if (!mounted) return;

      if (response.action == 'upi_collect' || response.action == 'upi_qr') {
        setState(() {
          _loading = false;
          _qrData = response.qrCode ?? '';
          _upiMessage = response.message;
        });
        widget.onPaymentStarted();
        _startUpiPolling(response.sabbpeOrderId);
        return;
      }

      if (response.action == 'form' && response.actionData != null) {
        _handleFormRedirect(response.actionData!);
        widget.onPaymentStarted();
        return;
      }

      if (response.action == 'post' && response.actionData != null) {
        _handlePostRedirect(response.actionData!);
        widget.onPaymentStarted();
        return;
      }

      if (response.action == 'redirect' || response.sabbpeOrderId.isNotEmpty) {
        _handleDirectSuccess(response);
        return;
      }

      setState(() {
        _loading = false;
        _error = response.message.isNotEmpty ? response.message : 'Payment failed. Please try again.';
      });
      widget.onPaymentError?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
      widget.onPaymentError?.call();
    }
  }

  void _handleFormRedirect(PaymentActionData actionData) {
    final url = actionData.url ?? '';
    final payloadStr = actionData.payload ?? '{}';
    final method = (actionData.method ?? 'POST').toUpperCase();

    final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

    PaymentRedirectHelper.handleFormRedirect(
      url: url,
      method: method,
      payload: payload,
    );
  }

  void _handlePostRedirect(PaymentActionData actionData) {
    final url = actionData.url ?? '';
    PaymentRedirectHelper.handlePostRedirect(url: url);
  }

  void _handleDirectSuccess(PaymentResponse response) {
    LocalStorageService.setDiamondPaymentContext(jsonEncode({
      'sabbpeOrderId': response.sabbpeOrderId,
      'merchantOrderRef': response.merchantOrderId.isNotEmpty ? response.merchantOrderId : response.sabbpeOrderId,
      'amount': widget.amount,
      'status': 'SUCCESS',
    }));
    widget.onPaymentStarted();
  }

  void _startUpiPolling(String sabbpeOrderId) {
    _upiPollTimer?.cancel();
    _upiPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final api = _cashfreeApi();
        final status = await api.checkDiamondPaymentStatus(sabbpeOrderId);

        if (!mounted) return;

        final st = status.paymentStatus.toUpperCase();
        if (st == 'SUCCESS') {
          _upiPollTimer?.cancel();
          LocalStorageService.setDiamondPaymentContext(jsonEncode({
            'sabbpeOrderId': sabbpeOrderId,
            'merchantOrderRef': sabbpeOrderId,
            'amount': widget.amount,
            'status': 'SUCCESS',
          }));
          widget.onPaymentStarted();
        } else if (st == 'FAILED' || st == 'USER_DROPPED' || st == 'EXPIRED') {
          _upiPollTimer?.cancel();
          setState(() {
            _loading = false;
            _error = status.message.isNotEmpty ? status.message : 'Payment failed';
          });
          widget.onPaymentError?.call();
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Amount display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            color: const Color(0xFF1A2332),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Payable', style: TextStyle(fontSize: 12, color: _textSecondary)),
              Text(
                '₹${_formatPrice(widget.amount)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Payment method tabs
        Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            color: const Color(0xFF1A1A1A),
          ),
          child: Row(
            children: [
              Expanded(child: _buildMethodTab('UPI', 'upi')),
              Expanded(child: _buildMethodTab('Apps', 'mobile')),
              Expanded(child: _buildMethodTab('Net Banking', 'netbanking')),
              Expanded(child: _buildMethodTab('Cards', 'cards')),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Payment method content
        _buildMethodContent(),

        // Error
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF2A1111),
              border: Border.all(color: const Color(0xFF6B2A2A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFD8B8B8))),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Pay button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(colors: [Color(0xFF0084FF), Color(0xFF005BB5)]),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _loading ? null : _initiatePayment,
                child: Center(
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 17, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${_formatPrice(widget.amount)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 12, color: Color(0xFF15EE01)),
            const SizedBox(width: 6),
            const Text('Secure checkout powered by Cashfree', style: TextStyle(fontSize: 9, color: _textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodTab(String label, String key) {
    final isActive = _selectedMethod == key;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMethod = key;
        _error = '';
      }),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive ? _primary : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodContent() {
    switch (_selectedMethod) {
      case 'upi':
        return _buildUpiSection();
      case 'mobile':
        return _buildMobileAppsSection();
      case 'netbanking':
        return _buildNetBankingSection();
      case 'cards':
        return _buildCardsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── UPI ──────────────────────────────────────────────────────────────────

  Widget _buildUpiSection() {
    if (_upiMessage.isNotEmpty && _qrData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
          color: const Color(0xFF141414),
        ),
        child: Column(
          children: [
            const Icon(Icons.timer, size: 32, color: _accent),
            const SizedBox(height: 8),
            Text(_upiMessage, style: const TextStyle(fontSize: 13, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Waiting for payment approval...', style: TextStyle(fontSize: 11, color: _textSecondary)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF141414),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildUpiToggle('Collect (VPA)', false),
              const SizedBox(width: 8),
              _buildUpiToggle('QR Code', true),
            ],
          ),
          const SizedBox(height: 12),
          if (!_showQr)
            Container(
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
                color: const Color(0xFF1E1E1E),
              ),
              child: TextField(
                controller: _vpaController,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter UPI VPA (e.g. name@upi)',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF5E5E5E)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('QR code will be generated on payment', style: TextStyle(fontSize: 12, color: _textSecondary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpiToggle(String label, bool isQr) {
    final isActive = _showQr == isQr;
    return GestureDetector(
      onTap: () => setState(() => _showQr = isQr),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? _primary : const Color(0xFF1E1E1E),
          border: Border.all(color: isActive ? _primary : _cardBorder),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : _textSecondary)),
      ),
    );
  }

  // ─── Mobile Apps ──────────────────────────────────────────────────────────

  Widget _buildMobileAppsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF141414),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: _mobileApps.length,
        itemBuilder: (context, index) {
          final app = _mobileApps[index];
          return GestureDetector(
            onTap: () => _initiatePayment(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
                color: const Color(0xFF1E1E1E),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(app['icon'] as IconData, size: 22, color: _accent),
                  const SizedBox(height: 4),
                  Text(
                    app['name'] as String,
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Net Banking ──────────────────────────────────────────────────────────

  Widget _buildNetBankingSection() {
    final filtered = _bankSearchController.text.isEmpty
        ? _banks
        : _banks.where((b) => b['name']!.toLowerCase().contains(_bankSearchController.text.toLowerCase())).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF141414),
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder),
              color: const Color(0xFF1E1E1E),
            ),
            child: TextField(
              controller: _bankSearchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search banks...',
                hintStyle: TextStyle(fontSize: 11, color: Color(0xFF5E5E5E)),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 16, color: _textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map((bank) {
              final isSelected = _selectedBankCode == bank['code'];
              return GestureDetector(
                onTap: () => setState(() => _selectedBankCode = bank['code']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? _primary : _cardBorder),
                    color: isSelected ? _primary.withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
                  ),
                  child: Text(
                    bank['name']!,
                    style: TextStyle(fontSize: 11, color: isSelected ? _accent : Colors.white),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Cards ────────────────────────────────────────────────────────────────

  Widget _buildCardsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF141414),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card type toggle
          Row(
            children: [
              _buildCardTypeToggle('Credit Card', 'CREDIT_CARD'),
              const SizedBox(width: 8),
              _buildCardTypeToggle('Debit Card', 'DEBIT_CARD'),
            ],
          ),
          const SizedBox(height: 12),
          _buildCardInput('Card Number', _cardNumberController, TextInputType.number, maxLength: 19),
          const SizedBox(height: 10),
          _buildCardInput('Card Holder Name', _cardHolderController, TextInputType.name),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildCardInput('MM', _cardExpiryMmController, TextInputType.number, maxLength: 2)),
              const SizedBox(width: 8),
              Expanded(child: _buildCardInput('YY', _cardExpiryYyController, TextInputType.number, maxLength: 2)),
              const SizedBox(width: 8),
              Expanded(child: _buildCardInput('CVV', _cardCvvController, TextInputType.number, maxLength: 4, obscure: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTypeToggle(String label, String type) {
    final isActive = _cardType == type;
    return GestureDetector(
      onTap: () => setState(() => _cardType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? _primary : const Color(0xFF1E1E1E),
          border: Border.all(color: isActive ? _primary : _cardBorder),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : _textSecondary)),
      ),
    );
  }

  Widget _buildCardInput(String hint, TextEditingController ctrl, TextInputType type, {int? maxLength, bool obscure = false}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF1E1E1E),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLength: maxLength,
        obscureText: obscure,
        style: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF5E5E5E)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final intValue = price.toInt();
    final buf = StringBuffer();
    final s = intValue.toString();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      count++;
      buf.write(s[i]);
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      } else if (count == 2 && i != 0 && s.length > 3) {
        final prev = i > 0 ? s[i - 1] : '';
        if (prev.isNotEmpty && prev != ',') {
          buf.write(',');
          count = 0;
        }
      }
    }
    return buf.toString().split('').reversed.join();
  }
}
