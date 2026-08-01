import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/cashfree_api.dart';
import '../../core/api/diamond_api.dart';
import '../../core/models/diamond_model.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import '../diamond_flow/widgets/diamond_cart_thumb.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  List<DiamondCartItem> _cartItems = [];
  Set<String> _selectedCartItemIds = {};
  bool _loading = true;
  bool _paying = false;
  Timer? _bannerTimer;
  String _payError = '';

  static const Duration _reservationDuration = Duration(minutes: 30);
  static const Color _primary = Color(0xFF0084FF);
  static const Color _accent = Color(0xFF3AC7FF);
  static const Color _cardBorder = Color(0xFF2E2E2E);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _fetchCart();
    _bannerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  DiamondApi _diamondApi() {
    final dio = ref.read(augmontDioProvider);
    return DiamondApi(dio);
  }

  Future<void> _fetchCart() async {
    setState(() => _loading = true);
    final api = _diamondApi();
    final result = await api.fetchDiamondCart();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['ok'] == true) {
        final raw = result['raw'] as Map<String, dynamic>? ?? {};
        final data = raw['data'];
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = (data['cartItems'] as List<dynamic>?) ??
              (data['items'] as List<dynamic>?) ??
              [];
        } else {
          items = [];
        }
        _cartItems = items
            .map((e) => DiamondCartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _selectedCartItemIds = _cartItems.map((i) => i.id).toSet();
      }
    });
  }

  Future<void> _removeFromCart(String cartItemId) async {
    final api = _diamondApi();
    final result = await api.removeDiamondCartItem(cartItemId);
    if (mounted && result['ok'] == true) {
      await _fetchCart();
    }
  }

  double get _selectedTotal {
    double total = 0;
    for (final item in _cartItems) {
      if (_selectedCartItemIds.contains(item.id)) {
        total += item.unitPrice * item.quantity;
      }
    }
    return total;
  }

  bool get _allSelected =>
      _cartItems.isNotEmpty &&
      _cartItems.every((item) => _selectedCartItemIds.contains(item.id));

  _ReservationInfo _getEarliestReservation() {
    DateTime? earliest;
    for (final item in _cartItems) {
      final created = item.createdAt;
      if (created == null) continue;
      final expiry = created.add(_reservationDuration);
      if (earliest == null ||
          expiry.isBefore(earliest.add(_reservationDuration))) {
        earliest = created;
      }
    }
    if (earliest == null) {
      return const _ReservationInfo(
          display: '30:00', progress: 1.0, expired: false);
    }
    final expiry = earliest.add(_reservationDuration);
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      return const _ReservationInfo(
          display: '00:00', progress: 0.0, expired: true);
    }
    final totalMs = _reservationDuration.inMilliseconds;
    final remainingMs = remaining.inMilliseconds;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return _ReservationInfo(
      display:
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      progress: remainingMs / totalMs,
      expired: false,
    );
  }

  bool _isAnyItemExpired() {
    for (final item in _cartItems) {
      final created = item.createdAt;
      if (created == null) continue;
      if (DateTime.now().isAfter(created.add(_reservationDuration)))
        return true;
    }
    return false;
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
    final intStr = buf.toString().split('').reversed.join();
    final decimals = (price - price.toInt()).toStringAsFixed(2).substring(1);
    return '$intStr$decimals';
  }

  Future<void> _proceedToPay() async {
    if (_selectedCartItemIds.isEmpty || _paying) return;
    setState(() {
      _paying = true;
      _payError = '';
    });
    try {
      final clientId = LocalStorageService.getDiamondClientId() ?? '';
      if (clientId.isEmpty) throw Exception('Please login again');

      final selectedItems =
          _cartItems.where((i) => _selectedCartItemIds.contains(i.id)).toList();
      final items = selectedItems
          .map((e) => {
                'id': e.id,
                'productId': e.productId,
                'amount': e.unitPrice,
              })
          .toList();

      final api = CashfreeApi(ref.read(augmontDioProvider));
      final response = await api.createDiamondPayment(
        clientId: clientId,
        totalAmount: _selectedTotal,
        items: items,
      );

      if (response.paymentSessionId.isEmpty) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Payment session ID is missing');
      }

      await LocalStorageService.setDiamondPaymentContext(jsonEncode({
        'type': 'diamond',
        'amount': _selectedTotal,
        'items': items,
        'sabbpeOrderId': response.sabbpeOrderId,
        'merchantOrderRef': response.merchantOrderId.isNotEmpty
            ? response.merchantOrderId
            : response.sabbpeOrderId,
      }));

      if (!mounted) return;
      context.go(AppRoutes.paymentGateway, extra: {
        'paymentSessionId': response.paymentSessionId,
        'orderId': response.merchantOrderId.isNotEmpty
            ? response.merchantOrderId
            : response.sabbpeOrderId,
        'amount': _selectedTotal,
      });
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted)
        setState(() {
          _payError = msg;
          _paying = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF293341), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.home),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Your Cart',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _primary))
                    : _cartItems.isEmpty
                        ? _buildEmptyState()
                        : _buildCartContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: _textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Your cart is empty',
                style: TextStyle(fontSize: 14, color: _textSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.go(AppRoutes.buyDiamonds),
              child: const Text(
                'Browse Diamonds',
                style: TextStyle(
                    fontSize: 13, color: _primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    final reservation = _getEarliestReservation();
    final anyExpired = _isAnyItemExpired();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reservation countdown banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: reservation.expired
                          ? [const Color(0xFF3B1A1A), const Color(0xFF1A0A0A)]
                          : [const Color(0xFF0A2A3B), const Color(0xFF0A1520)],
                    ),
                    border: Border.all(
                      color: reservation.expired
                          ? const Color(0xFF5C2020)
                          : const Color(0xFF0067B8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.expired
                                  ? 'Reservation Expired'
                                  : 'Complete your payment',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: reservation.expired
                                    ? const Color(0xFFFF6B6B)
                                    : _accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reservation.expired
                                  ? 'Your reservation has expired. Please reserve the product again.'
                                  : 'Your selected product has been reserved exclusively for you.',
                              style: TextStyle(
                                fontSize: 8,
                                height: 1.4,
                                color: reservation.expired
                                    ? const Color(0xFFFF9E9E)
                                    : _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!reservation.expired) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CustomPaint(
                            painter: _ReservationTimerPainter(
                              progress: reservation.progress,
                              color: _accent,
                            ),
                            child: Center(
                              child: Text(
                                reservation.display,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Select All / Deselect All with count
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_allSelected) {
                            _selectedCartItemIds.clear();
                          } else {
                            _selectedCartItemIds =
                                _cartItems.map((i) => i.id).toSet();
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _allSelected
                                    ? _primary
                                    : const Color(0xFF515151),
                                width: 2,
                              ),
                              color:
                                  _allSelected ? _primary : Colors.transparent,
                            ),
                            child: _allSelected
                                ? const Icon(Icons.check,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _allSelected ? 'Deselect All' : 'Select All',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _primary),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedCartItemIds.length} of ${_cartItems.length} selected',
                      style:
                          const TextStyle(fontSize: 10, color: _textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cart item cards
                ...List.generate(_cartItems.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCartItemCard(_cartItems[index]),
                  );
                }),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Bottom section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          child: Column(
            children: [
              // Total Payable
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cardBorder),
                  color: const Color(0xFF26313B),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Total Payable',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '₹${_formatPrice(_selectedTotal)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_payError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_payError,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.redAccent),
                      textAlign: TextAlign.center),
                ),
              // Proceed to Pay button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient:
                        anyExpired || _selectedCartItemIds.isEmpty || _paying
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF006FC7), Color(0xFF00457C)]),
                    color: anyExpired || _selectedCartItemIds.isEmpty || _paying
                        ? const Color(0xFF2A2A2A)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: anyExpired
                          ? () => context.go(AppRoutes.buyDiamonds)
                          : _selectedCartItemIds.isEmpty || _paying
                              ? null
                              : _proceedToPay,
                      child: Center(
                        child: _paying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                anyExpired
                                    ? 'Reserve Again'
                                    : 'Proceed to Pay${_selectedCartItemIds.isNotEmpty ? ' (₹${_formatPrice(_selectedTotal)})' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      anyExpired || _selectedCartItemIds.isEmpty
                                          ? _textSecondary
                                          : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(DiamondCartItem item) {
    final isSelected = _selectedCartItemIds.contains(item.id);
    final created = item.createdAt;
    final isExpired = created != null &&
        DateTime.now().isAfter(created.add(_reservationDuration));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? (isExpired ? const Color(0xFF5C2020) : _primary)
              : _cardBorder,
        ),
        color: const Color(0xFF26313B),
        boxShadow: isSelected && !isExpired
            ? [
                BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    spreadRadius: 4)
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCartItemIds.remove(item.id);
                    } else {
                      _selectedCartItemIds.add(item.id);
                    }
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? _primary : const Color(0xFF515151),
                      width: 2,
                    ),
                    color: isSelected ? _primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // Thumbnail
              DiamondCartThumb(item: item, placeholderColor: _accent),
              const SizedBox(width: 10),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName.isNotEmpty
                          ? item.productName
                          : 'Diamond',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF7E7E7E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accent),
                    ),
                  ],
                ),
              ),

              // Remove button
              GestureDetector(
                onTap: () => _removeFromCart(item.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(fontSize: 10, color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),

          // Per-item reservation timer
          if (created != null) ...[
            const SizedBox(height: 8),
            _CartItemTimer(
              createdAt: created,
              onExpired: () => _removeFromCart(item.id),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reservation helpers ──────────────────────────────────────────────────────

class _ReservationInfo {
  final String display;
  final double progress;
  final bool expired;

  const _ReservationInfo({
    required this.display,
    required this.progress,
    required this.expired,
  });
}

class _ReservationTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ReservationTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    final bgPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ReservationTimerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Per-item countdown timer ─────────────────────────────────────────────────

class _CartItemTimer extends StatefulWidget {
  final DateTime createdAt;
  final VoidCallback? onExpired;

  const _CartItemTimer({required this.createdAt, this.onExpired});

  @override
  State<_CartItemTimer> createState() => _CartItemTimerState();
}

class _CartItemTimerState extends State<_CartItemTimer> {
  late Timer _timer;
  late Duration _remaining;
  bool _expired = false;
  static const Duration _duration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  void _calculateRemaining() {
    final expiry = widget.createdAt.add(_duration);
    final now = DateTime.now();
    final diff = expiry.difference(now);

    if (diff.isNegative) {
      if (!_expired) {
        _expired = true;
        widget.onExpired?.call();
        _timer.cancel();
      }
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final progress = _remaining.inSeconds / _duration.inSeconds;
    final isActive = !_expired;

    final color = isActive ? const Color(0xFF3AC7FF) : const Color(0xFFFF6B6B);
    final bgColor = isActive
        ? const Color(0xFF0084FF).withValues(alpha: 0.1)
        : const Color(0xFF5C2020).withValues(alpha: 0.3);
    final borderColor = isActive
        ? const Color(0xFF0084FF).withValues(alpha: 0.3)
        : const Color(0xFF5C2020);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (isActive) ...[
            SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter:
                    _ReservationTimerPainter(progress: progress, color: color),
                child: Center(
                  child: Text(
                    '$minutes:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reserved for you',
              style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
            ),
          ] else ...[
            Text(
              'Reservation expired',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              '\u00B7 Reserve again',
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
