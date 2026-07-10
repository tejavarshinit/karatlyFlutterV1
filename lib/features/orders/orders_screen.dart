import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/augmont_model.dart';
import '../../core/models/diamond_model.dart';
import '../../core/services/orders_provider.dart';

enum MetalFilter { all, gold, silver, diamond }

enum OrderTypeFilter { all, buy, sell, redeem }

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  MetalFilter _metalFilter = MetalFilter.all;
  OrderTypeFilter _typeFilter = OrderTypeFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).fetchAllOrders());
  }

  // ── Color schemes per metal ──
  _ColorScheme get _colors {
    switch (_metalFilter) {
      case MetalFilter.diamond:
        return _ColorScheme(
          bg1: const Color(0xFF0A2A3B),
          bg2: Colors.black,
          accent: const Color(0xFF3AC7FF),
          border: const Color(0xFF0067B8),
          panel: const Color(0xFF0A1520),
          heroBg1: const Color(0xFF003A68),
          heroBg2: const Color(0xFF0D1117),
          activeGradient: [const Color(0xFF0073CE), const Color(0xFF003A68)],
          activeText: Colors.white,
          inactiveText: const Color(0xFF8C8B8B),
          iconBg: const Color(0xFF0A2A3B),
          iconColor: const Color(0xFF3AC7FF),
          badgeBg: const Color(0xFF0A2A3B),
          badgeText: const Color(0xFF3AC7FF),
        );
      case MetalFilter.silver:
        return _ColorScheme(
          bg1: const Color(0xFF293341),
          bg2: Colors.black,
          accent: Colors.white,
          border: const Color(0xFF7388A5),
          panel: const Color(0xFF111821),
          heroBg1: const Color(0xFF495C73),
          heroBg2: const Color(0xFF0D1117),
          activeGradient: [Colors.white, const Color(0xFF999999)],
          activeText: Colors.black,
          inactiveText: const Color(0xFF8C8B8B),
          iconBg: const Color(0xFF1D2530),
          iconColor: const Color(0xFF6DD6FF),
          badgeBg: const Color(0xFF243736),
          badgeText: const Color(0xFF6DD6FF),
        );
      case MetalFilter.gold:
      case MetalFilter.all:
        return _ColorScheme(
          bg1: const Color(0xFF293341),
          bg2: Colors.black,
          accent: const Color(0xFFF7CD57),
          border: const Color(0xFFB28A3B),
          panel: const Color(0xFF1A1710),
          heroBg1: const Color(0xFF1E2A28),
          heroBg2: const Color(0xFF6C5123),
          activeGradient: [const Color(0xFFFED75D), const Color(0xFFECB000), const Color(0xFFD48D00)],
          activeText: Colors.black,
          inactiveText: const Color(0xFF8C8B8B),
          iconBg: const Color(0xFF3D3214),
          iconColor: const Color(0xFFF7CD57),
          badgeBg: const Color(0xFF38342C),
          badgeText: const Color(0xFFF7CD57),
        );
    }
  }

  List<_DisplayOrder> _getFilteredOrders(OrdersState state) {
    List<_DisplayOrder> displayOrders = [];

    if (_metalFilter == MetalFilter.diamond) {
      displayOrders = state.diamondOrders.map((o) => _DisplayOrder(
        id: o.lockId,
        type: 'BUY',
        amount: o.totalAmount,
        date: o.createdAt,
        status: o.paymentStatus.isNotEmpty ? o.paymentStatus : (o.orderStatus.isNotEmpty ? o.orderStatus : 'Pending'),
        metalName: 'Diamond',
        displayName: 'Diamond',
        badgeLabel: 'Invested',
        transactionId: o.orderId,
        orderReference: o.orderReference,
        isDiamond: true,
      )).toList();
    } else {
      for (final o in state.orders) {
        final metalMatch = _metalFilter == MetalFilter.all ||
            o.metalType.toLowerCase() == _metalFilter.name.toLowerCase();
        if (!metalMatch) continue;

        final typeUpper = o.type.toUpperCase();
        final typeMatch = _typeFilter == OrderTypeFilter.all ||
            (_typeFilter == OrderTypeFilter.buy && typeUpper == 'BUY') ||
            (_typeFilter == OrderTypeFilter.sell && typeUpper == 'SELL') ||
            (_typeFilter == OrderTypeFilter.redeem && typeUpper == 'REDEEM');
        if (!typeMatch) continue;

        final metalName = o.metalType.toLowerCase() == 'silver' ? 'Silver' : 'Gold';
        final displayName = typeUpper == 'BUY' ? 'Digital $metalName' : metalName;
        final badgeLabel = typeUpper == 'BUY' ? 'Invested' : typeUpper;

        displayOrders.add(_DisplayOrder(
          id: o.id,
          type: typeUpper,
          amount: o.amount,
          gold: o.gold,
          rate: o.rate,
          date: o.date,
          status: o.status,
          metalName: metalName,
          displayName: displayName,
          badgeLabel: badgeLabel,
          transactionId: o.orderReference,
        ));
      }
    }

    displayOrders.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime(0);
      final dateB = DateTime.tryParse(b.date) ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    return displayOrders;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      final time = DateFormat('h:mm a').format(d);
      if (isToday) return 'Today - $time';
      return '${DateFormat('d MMM').format(d)} - $time';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatAmountShort(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final colors = _colors;
    final filteredOrders = _getFilteredOrders(state);

    // Counts for hero card
    final augmontFiltered = _metalFilter == MetalFilter.diamond
        ? <AugmontOrder>[]
        : state.orders.where((o) => _metalFilter == MetalFilter.all || o.metalType.toLowerCase() == _metalFilter.name.toLowerCase()).toList();

    final diamondFiltered = _metalFilter == MetalFilter.diamond ? state.diamondOrders : <DiamondOrder>[];

    final buyCount = _metalFilter == MetalFilter.diamond
        ? state.diamondOrders.length
        : augmontFiltered.where((o) => o.type.toUpperCase() == 'BUY').length;
    final sellCount = _metalFilter == MetalFilter.diamond
        ? 0
        : augmontFiltered.where((o) => o.type.toUpperCase() == 'SELL').length;
    final redeemCount = _metalFilter == MetalFilter.diamond
        ? 0
        : augmontFiltered.where((o) => o.type.toUpperCase() == 'REDEEM').length;
    final totalAmt = _metalFilter == MetalFilter.diamond
        ? diamondFiltered.fold<double>(0, (sum, o) => sum + (o.totalAmount))
        : augmontFiltered.fold<double>(0, (sum, o) => sum + o.amount);
    final totalOrdersCount = _metalFilter == MetalFilter.diamond ? diamondFiltered.length : augmontFiltered.length;
    final isDiamond = _metalFilter == MetalFilter.diamond;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.97, -0.38),
          radius: 1.04,
          colors: [colors.bg1, colors.bg2],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(colors),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── Hero Summary Card ──
                      _buildHeroCard(colors, totalAmt, totalOrdersCount, buyCount, sellCount, redeemCount, isDiamond, state),

                      const SizedBox(height: 18),

                      // ── Metal Filter ──
                      _buildMetalFilter(colors),

                      const SizedBox(height: 14),

                      // ── Type Filter ──
                      _buildTypeFilter(colors, isDiamond),

                      const SizedBox(height: 16),

                      // ── Order List ──
                      _buildOrderList(state, filteredOrders, colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(Icons.arrow_back_ios_new, size: 20, color: colors.accent),
          ),
          const SizedBox(width: 8),
          Text(
            'Orders',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.accent,
            ),
          ),
          const Spacer(),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.border, width: 1),
              color: colors.panel,
            ),
            child: const Icon(Icons.notifications_outlined, size: 14, color: Color(0xFFC1C1C1)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(_ColorScheme colors, double totalAmt, int totalOrders, int buyCount, int sellCount, int redeemCount, bool isDiamond, OrdersState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 19, 16, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 1),
          gradient: LinearGradient(
            begin: const Alignment(2.2, -1.0),
            end: const Alignment(-0.5, 0.5),
            colors: [colors.heroBg1, colors.heroBg2],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_metalFilter == MetalFilter.all ? "ALL" : _metalFilter.name.toUpperCase()} ORDERS',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)),
                    ),
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(colors: colors.activeGradient).createShader(bounds),
                      child: Text(
                        'Rs.${_formatAmountShort(totalAmt)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalOrders total orders',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (!isDiamond)
              Row(
                children: [
                  _buildCountBox('BUY', buyCount, colors),
                  const SizedBox(width: 8),
                  _buildCountBox('SELL', sellCount, colors),
                  const SizedBox(width: 8),
                  _buildCountBox('REDEEM', redeemCount, colors),
                ],
              )
            else
              Row(
                children: [
                  _buildCountBox('BUY', buyCount, colors),
                  const SizedBox(width: 8),
                  _buildCountBox('PAID', state.diamondOrders.where((o) => o.paymentStatus == 'success').length, colors),
                  const SizedBox(width: 8),
                  _buildCountBox('PENDING', state.diamondOrders.where((o) => o.paymentStatus != 'success').length, colors),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBox(String label, int count, _ColorScheme colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4E4E4E), width: 1),
          color: colors.panel,
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(colors: colors.activeGradient).createShader(bounds),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.27),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetalFilter(_ColorScheme colors) {
    final metals = ['All', 'Gold', 'Silver', 'Diamond'];
    final filterValues = [MetalFilter.all, MetalFilter.gold, MetalFilter.silver, MetalFilter.diamond];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('Filter by Asset', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4E4E4E), width: 1),
                color: const Color(0xFF24201A),
              ),
              child: Row(
                children: List.generate(metals.length, (i) {
                  final isActive = _metalFilter == filterValues[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _metalFilter = filterValues[i];
                        _typeFilter = OrderTypeFilter.all;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: isActive ? LinearGradient(colors: colors.activeGradient) : null,
                          color: isActive ? null : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            metals[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? colors.activeText : colors.inactiveText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(_ColorScheme colors, bool isDiamond) {
    final filters = isDiamond ? ['All', 'Buy'] : ['All', 'Buy', 'Sell', 'Redeem'];
    final filterValues = isDiamond
        ? [OrderTypeFilter.all, OrderTypeFilter.buy]
        : [OrderTypeFilter.all, OrderTypeFilter.buy, OrderTypeFilter.sell, OrderTypeFilter.redeem];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 1),
          color: colors.panel,
        ),
        child: Row(
          children: List.generate(filters.length, (i) {
            final isActive = _typeFilter == filterValues[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _typeFilter = filterValues[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isActive ? LinearGradient(colors: colors.activeGradient) : null,
                    color: isActive ? null : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      filters[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: isActive ? colors.activeText : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOrderList(OrdersState state, List<_DisplayOrder> filteredOrders, _ColorScheme colors) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFF7CD57), strokeWidth: 2)),
      );
    }

    if (filteredOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: colors.inactiveText),
              const SizedBox(height: 16),
              Text('No orders found', style: TextStyle(color: colors.inactiveText, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: filteredOrders.map((order) => _buildOrderCard(order, colors)).toList(),
      ),
    );
  }

  Widget _buildOrderCard(_DisplayOrder order, _ColorScheme colors) {
    final isSell = order.type == 'SELL';
    final isRedeem = order.type == 'REDEEM';
    final isDiamondOrder = order.isDiamond;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1),
        color: colors.panel,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDiamondOrder
                  ? const Color(0xFF0A2A3B)
                  : isSell
                      ? const Color(0xFF213435)
                      : isRedeem
                          ? const Color(0xFF1A2530)
                          : colors.iconBg,
            ),
            child: Icon(
              isDiamondOrder
                  ? Icons.diamond_outlined
                  : isSell
                      ? Icons.arrow_upward
                      : isRedeem
                          ? Icons.inventory_2_outlined
                          : Icons.arrow_downward,
              size: 16,
              color: isDiamondOrder
                  ? const Color(0xFF3AC7FF)
                  : isSell
                      ? const Color(0xFF6DD6FF)
                      : isRedeem
                          ? Colors.white
                          : colors.iconColor,
            ),
          ),
          const SizedBox(width: 12),

          // ── Details ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Badge
                Row(
                  children: [
                    Text(
                      order.displayName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isDiamondOrder
                            ? const Color(0xFF0A2A3B)
                            : isSell
                                ? const Color(0xFF243736)
                                : isRedeem
                                    ? const Color(0xFF242C36)
                                    : colors.badgeBg,
                      ),
                      child: Text(
                        order.badgeLabel,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isDiamondOrder
                              ? const Color(0xFF3AC7FF)
                              : isSell
                                  ? const Color(0xFF6DD6FF)
                                  : isRedeem
                                      ? Colors.white
                                      : colors.badgeText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Reference, grams, rate, date
                Text(
                  '${order.orderReference.isNotEmpty ? "${order.orderReference} - " : ""}'
                  '${order.gold != null && order.gold! > 0 ? "${order.gold!.toStringAsFixed(2)}g" : ""}'
                  '${(order.gold != null && order.gold! > 0 && order.rate != null && order.rate! > 0) ? " - " : ""}'
                  '${order.rate != null && order.rate! > 0 ? "Rs.${order.rate!.toStringAsFixed(0)}/g" : ""}'
                  '${(order.rate != null && order.rate! > 0 || (order.gold != null && order.gold! > 0)) ? " - " : ""}'
                  '${_formatDate(order.date)}',
                  style: const TextStyle(fontSize: 8, color: Color(0xFF6E6E6E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 1),

                // GST notice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: colors.badgeBg,
                  ),
                  child: Text(
                    'Applicable GST is reflected in the invoice.',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: colors.badgeText),
                  ),
                ),

                // Invoice button (not for diamond)
                if (!isDiamondOrder) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _downloadInvoice(order),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, size: 12, color: colors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Invoice',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Amount + Status ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(order.amount),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                order.status,
                style: TextStyle(
                  fontSize: 8,
                  color: order.status.toLowerCase() == 'pending'
                      ? const Color(0xFFFFCD0F)
                      : const Color(0xFF15EE01),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadInvoice(_DisplayOrder order) async {
    // TODO: Implement invoice download with PDF generation
    // For now show a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice download for ${order.type} order'),
        backgroundColor: const Color(0xFF242320),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Internal display model ──
class _DisplayOrder {
  final String id;
  final String type;
  final double amount;
  final double? gold;
  final double? rate;
  final String date;
  final String status;
  final String metalName;
  final String displayName;
  final String badgeLabel;
  final String transactionId;
  final String orderReference;
  final bool isDiamond;

  const _DisplayOrder({
    this.id = '',
    this.type = '',
    this.amount = 0,
    this.gold,
    this.rate,
    this.date = '',
    this.status = 'Pending',
    this.metalName = '',
    this.displayName = '',
    this.badgeLabel = '',
    this.transactionId = '',
    this.orderReference = '',
    this.isDiamond = false,
  });
}

// ── Color scheme helper ──
class _ColorScheme {
  final Color bg1;
  final Color bg2;
  final Color accent;
  final Color border;
  final Color panel;
  final Color heroBg1;
  final Color heroBg2;
  final List<Color> activeGradient;
  final Color activeText;
  final Color inactiveText;
  final Color iconBg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeText;

  const _ColorScheme({
    required this.bg1,
    required this.bg2,
    required this.accent,
    required this.border,
    required this.panel,
    required this.heroBg1,
    required this.heroBg2,
    required this.activeGradient,
    required this.activeText,
    required this.inactiveText,
    required this.iconBg,
    required this.iconColor,
    required this.badgeBg,
    required this.badgeText,
  });
}
