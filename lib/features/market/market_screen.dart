import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/models/gold_rate_model.dart';
import '../../core/services/market_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/models/product_model.dart';
import '../../core/storage/local_storage.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final rateState = ref.watch(rateProvider);
    final isSilver = market.metalType == 'silver';

    final accentColor = isSilver ? Colors.white : const Color(0xFFF7CD57);
    final borderColor = isSilver ? const Color(0xFF7388A5) : const Color(0xFF8E742F);
    final panelBg = isSilver ? const Color(0xFF111821) : const Color(0xFF1A1710);

    final goldBuyPrice = rateState.currentRate?.buyPrice ?? 0;
    final silverBuyPrice = rateState.currentRate?.silver.buyPrice ?? 0;
    final chipPrice = isSilver ? silverBuyPrice : goldBuyPrice;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.9755, -0.3792),
          radius: 1.04,
          colors: [isSilver ? const Color(0xFF293341) : const Color(0xFF4A3A1E), Colors.black],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isSilver: isSilver, accentColor: accentColor),
              const SizedBox(height: 20),
              _buildRateAnalyticsCard(
                market: market,
                isSilver: isSilver,
                accentColor: accentColor,
                borderColor: borderColor,
                panelBg: panelBg,
                chipPrice: chipPrice,
              ),
              const SizedBox(height: 24),
              _buildSearchBar(
                market: market,
                isSilver: isSilver,
                borderColor: borderColor,
              ),
              const SizedBox(height: 24),
              if (market.searchQuery.trim().isEmpty)
                _buildProductsSection(market: market, isSilver: isSilver),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isSilver, required Color accentColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.go(AppRoutes.home),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: accentColor, size: 18),
        ),
        Image.asset(
          'assets/images/KaratlyLOGO-removebg-preview.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.notifications),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D170D),
              border: Border.all(color: const Color(0xFFE8B438)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEE0105),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateAnalyticsCard({
    required MarketState market,
    required bool isSilver,
    required Color accentColor,
    required Color borderColor,
    required Color panelBg,
    required double chipPrice,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        gradient: const LinearGradient(
          begin: Alignment(-0.25, 1.0),
          end: Alignment(0.25, -1.0),
          colors: [Color(0xFF1E2A28), Color(0xFF6C5123)],
          stops: [0.6448, 0.9645],
        ),
      ),
      child: Column(
        children: [
          _buildCardTopRow(market: market, isSilver: isSilver, accentColor: accentColor),
          const SizedBox(height: 32),
          _buildPeriodSelector(market: market, isSilver: isSilver, accentColor: accentColor, borderColor: borderColor),
          const SizedBox(height: 16),
          _buildDatePriceChip(isSilver: isSilver, accentColor: accentColor, chipPrice: chipPrice),
          const SizedBox(height: 8),
          _buildChart(market: market, isSilver: isSilver),
          const SizedBox(height: 4),
          _buildLegend(isSilver: isSilver),
          const SizedBox(height: 16),
          _buildCtaButton(market: market, isSilver: isSilver),
        ],
      ),
    );
  }

  Widget _buildCardTopRow({required MarketState market, required bool isSilver, required Color accentColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate Analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Buy & Sell rate trend',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        _buildMetalToggle(market: market, isSilver: isSilver, accentColor: accentColor),
      ],
    );
  }

  Widget _buildMetalToggle({required MarketState market, required bool isSilver, required Color accentColor}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF24201A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildMetalChip(
            label: 'Gold',
            isSelected: !isSilver,
            accentColor: const Color(0xFFF7CD57),
            onTap: () => ref.read(marketProvider.notifier).setMetalType('gold'),
          ),
          _buildMetalChip(
            label: 'Silver',
            isSelected: isSilver,
            accentColor: Colors.white,
            onTap: () => ref.read(marketProvider.notifier).setMetalType('silver'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetalChip({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFFFED55C), Color(0xFFDA9500)])
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector({
    required MarketState market,
    required bool isSilver,
    required Color accentColor,
    required Color borderColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['3D', '1W', '1M', '1Y'].map((period) {
        final isSelected = market.ratePeriod == period;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => ref.read(marketProvider.notifier).setRatePeriod(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? (isSilver ? const Color(0xFF1D2530) : const Color(0xFF38342C)) : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: isSelected ? Border.all(color: isSilver ? const Color(0xFF7388A5) : const Color(0xFFB17B21)) : null,
              ),
              child: Text(
                period,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? accentColor : Colors.grey[500],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePriceChip({required bool isSilver, required Color accentColor, required double chipPrice}) {
    final now = DateTime.now();
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF38342C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF777777)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dateStr, style: TextStyle(fontSize: 8, color: Colors.grey[400])),
            Text(
              chipPrice > 0 ? 'Rs.${chipPrice.toStringAsFixed(0)}' : '---',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart({required MarketState market, required bool isSilver}) {
    if (market.loadingChart) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: isSilver ? Colors.white : const Color(0xFFF7CD57)),
        ),
      );
    }

    if (market.chartData.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            market.error ?? 'No rate history available',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
      );
    }

    final data = _subsampleData(market.chartData, 40);
    final buySpots = <FlSpot>[];
    final sellSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      if (point.buyRate > 0) buySpots.add(FlSpot(i.toDouble(), point.buyRate));
      if (point.sellRate > 0) sellSpots.add(FlSpot(i.toDouble(), point.sellRate));
    }

    final allValues = [...buySpots.map((s) => s.y), ...sellSpots.map((s) => s.y)];
    final rawMin = allValues.isEmpty ? 0.0 : allValues.reduce(math.min);
    final rawMax = allValues.isEmpty ? 100.0 : allValues.reduce(math.max);
    final range = rawMax - rawMin;
    // Ensure minimum range so Y-axis labels don't overlap
    final minRange = rawMin * 0.05;
    final adjustedRange = range < minRange ? minRange : range;
    final mid = (rawMin + rawMax) / 2;
    final minY = allValues.isEmpty ? 0.0 : (mid - adjustedRange / 2);
    final maxY = allValues.isEmpty ? 100.0 : (mid + adjustedRange / 2);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
      decoration: BoxDecoration(
        color: isSilver ? const Color(0xFF0D1117) : const Color(0xFF15120F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
              dashArray: [3, 6],
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      'Rs.${(value / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final point = data[idx];
                  String label;
                  try {
                    final d = DateTime.parse(point.date);
                    label = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  } catch (_) {
                    label = point.label.length > 8 ? point.label.substring(0, 8) : point.label;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            if (buySpots.isNotEmpty)
              LineChartBarData(
                spots: buySpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: isSilver ? const Color(0xFF9AA4B4) : const Color(0xFFF8CF59),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            if (sellSpots.isNotEmpty)
              LineChartBarData(
                spots: sellSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: const Color(0xFF3AC7FF),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xF00F172A),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.all(10),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isBuy = buySpots.contains(spot);
                  return LineTooltipItem(
                    'Rs.${spot.y.toStringAsFixed(0)}\n',
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    children: [
                      TextSpan(
                        text: isBuy ? 'Buy Rate' : 'Sell Rate',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (data, indices) {
              return indices.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.white.withValues(alpha: 0.15), dashArray: [4, 4]),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend({required bool isSilver}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        _legendDot(color: Colors.white, label: 'Buy'),
        const SizedBox(width: 24),
        _legendDot(color: const Color(0xFF3AC7FF), label: 'Sell'),
      ],
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildCtaButton({required MarketState market, required bool isSilver}) {
    return _CtaShimmerButton(
      isSilver: isSilver,
      metalType: market.metalType,
      onTap: () => context.go('/buy-gold/select?metal=${market.metalType}'),
    );
  }

  Widget _buildSearchBar({
    required MarketState market,
    required bool isSilver,
    required Color borderColor,
  }) {
    final suggestions = market.searchQuery.trim().isNotEmpty ? market.filteredProducts.take(5).toList() : <Product>[];

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1710),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => ref.read(marketProvider.notifier).setSearchQuery(v),
                style: const TextStyle(fontSize: 12, color: Color(0xFFEDEDED)),
                decoration: InputDecoration(
                  hintText: 'Search ${market.metalType} coins',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF4E4E4E)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4E4E4E), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            // Search suggestions dropdown
            if (market.searchQuery.trim().isNotEmpty)
              Positioned(
                top: 48,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF11100D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSilver ? const Color(0x8C7388A5) : const Color(0x59E8B438)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 45)],
                  ),
                  child: market.loadingProducts
                      ? const Padding(padding: EdgeInsets.all(16), child: Text('Searching products...', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))))
                      : suggestions.isEmpty
                          ? const Padding(padding: EdgeInsets.all(16), child: Text('No matching products', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))))
                          : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 500),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              itemBuilder: (context, index) {
                                final item = suggestions[index];
                                final isSilverItem = item.metalType.toLowerCase().contains('silver');
                                return InkWell(
                                  onTap: () {
                                    ref.read(marketProvider.notifier).setSearchQuery(item.name);
                                    _searchController.text = item.name;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(children: [
                                      _CoinIcon(isSilver: isSilverItem, size: 40),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, overflow: TextOverflow.ellipsis), maxLines: 1),
                                          const SizedBox(height: 2),
                                          Text('${item.sku} | ${item.purity} | ${item.productWeight}', style: const TextStyle(fontSize: 10, color: Color(0xFF8D8B87))),
                                        ]),
                                      ),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsSection({required MarketState market, required bool isSilver}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request physical delivery',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          isSilver ? 'Silver products from Augmont' : 'Gold products from Augmont',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        if (market.loadingProducts)
          _buildLoadingProducts()
        else if (market.filteredProducts.isEmpty)
          _buildEmptyProducts(market: market, isSilver: isSilver)
        else
          ...market.filteredProducts.map((product) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProductCard(product: product, isSilver: isSilver),
          )),
      ],
    );
  }

  Widget _buildLoadingProducts() {
    return Column(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2520),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4E4E4E)),
          ),
        ),
      )),
    );
  }

  Widget _buildEmptyProducts({required MarketState market, required bool isSilver}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1710),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Text(
        market.searchQuery.trim().isNotEmpty
            ? 'No matching ${market.metalType} products'
            : 'No ${market.metalType} products available',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
    );
  }

  List<RateHistoryPoint> _subsampleData(List<RateHistoryPoint> data, int maxPoints) {
    if (data.length <= maxPoints) return data;
    final step = (data.length / maxPoints).ceil();
    final result = <RateHistoryPoint>[];
    for (int i = 0; i < data.length; i += step) {
      result.add(data[i]);
    }
    if (result.last != data.last) result.add(data.last);
    return result;
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

// ── Product Card ──
// ── CTA Shimmer Button ──
class _CtaShimmerButton extends StatefulWidget {
  final bool isSilver;
  final String metalType;
  final VoidCallback onTap;

  const _CtaShimmerButton({required this.isSilver, required this.metalType, required this.onTap});

  @override
  State<_CtaShimmerButton> createState() => _CtaShimmerButtonState();
}

class _CtaShimmerButtonState extends State<_CtaShimmerButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isSilver ? [Colors.white, Colors.grey[400]!] : [const Color(0xFFFED45C), const Color(0xFFDB9502)],
            ),
          ),
          child: Stack(
            children: [
              Row(children: [
                const SizedBox(width: 12),
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.isSilver ? 'BUY SILVER NOW' : 'BUY GOLD NOW',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('Secure \u00B7 Fast \u00B7 Trusted', style: TextStyle(fontSize: 10, color: Colors.grey[800])),
                  ]),
                ),
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
              ]),
              // Shimmer sweep
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final shimmerPos = _controller.value;
                  return Positioned(
                    left: -10 + shimmerPos * 120,
                    top: 0, bottom: 0,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        width: 20,
                        transform: Matrix4.identity()..rotateZ(-0.2),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.transparent, Colors.white60, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product Card with Balance Check ──
class _ProductCard extends StatefulWidget {
  final Product product;
  final bool isSilver;

  const _ProductCard({required this.product, required this.isSilver});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  String? _redeemError;
  bool _checkingBalance = false;

  Future<void> _handleRedeem() async {
    final product = widget.product;
    final productMetal = product.metalType.toLowerCase();
    final isSilverProduct = productMetal.contains('silver');
    final productWeight = double.tryParse(product.productWeight.isNotEmpty ? product.productWeight : product.redeemWeight) ?? 0;

    // Balance check
    if (productWeight > 0) {
      setState(() { _checkingBalance = true; _redeemError = null; });
      try {
        final augmontApi = AugmontApi(Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )));
        // Try to get uniqueId
        final augmontRaw = LocalStorageService.getAugmontUser();
        String? uid;
        if (augmontRaw != null && augmontRaw.isNotEmpty) {
          try { uid = (jsonDecode(augmontRaw) as Map)['uniqueId']?.toString(); } catch (_) {}
        }
        if (uid == null || uid.isEmpty) {
          final profile = LocalStorageService.getUserProfile();
          uid = profile?['uniqueId']?.toString();
        }
        if (uid != null && uid.isNotEmpty) {
          final pbRes = await augmontApi.fetchAugmontPassbook(uid);
          if (pbRes['ok'] == true) {
            final pb = (pbRes['passbook'] as Map<String, dynamic>?) ?? {};
            final userBalance = isSilverProduct
                ? (double.tryParse(pb['silverGrms']?.toString() ?? '') ?? double.tryParse(pb['silverBalance']?.toString() ?? '') ?? 0)
                : (double.tryParse(pb['goldGrms']?.toString() ?? '') ?? double.tryParse(pb['goldBalance']?.toString() ?? '') ?? 0);
            if (userBalance < productWeight) {
              setState(() {
                _redeemError = 'Insufficient balance. You have ${userBalance.toStringAsFixed(4)}g of ${isSilverProduct ? 'silver' : 'gold'} but this product requires ${productWeight}g.';
              });
              return;
            }
          }
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() { _checkingBalance = false; });
    }
    context.go('/sell/gold-coin/1?metal=${widget.isSilver ? 'silver' : 'gold'}');
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isSilverProduct = product.metalType.toLowerCase().contains('silver');
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1710),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4E4E4E)),
          ),
          child: Row(
            children: [
              _CoinIcon(isSilver: isSilverProduct, size: 50),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${product.purity} | ${product.productWeight.isNotEmpty ? product.productWeight : product.redeemWeight}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _checkingBalance ? null : _handleRedeem,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: widget.isSilver ? [Colors.white, Colors.grey[400]!] : [const Color(0xFFF7CD57), const Color(0xFFE5AF35)],
                          ),
                        ),
                        child: Text(
                          _checkingBalance ? 'Checking...' : 'Tap to redeem',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(product.status, style: const TextStyle(fontSize: 12, color: Color(0xFF15EE01))),
            ],
          ),
        ),
        if (_redeemError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF2A1200),
              border: Border.all(color: const Color(0xFF5C2A0A)),
            ),
            child: Row(children: [
              Expanded(child: Text(_redeemError!, style: const TextStyle(fontSize: 10, color: Color(0xFFFF8A65)))),
              GestureDetector(
                onTap: () => setState(() => _redeemError = null),
                child: const Text('Dismiss', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFF7CD57))),
              ),
            ]),
          ),
      ],
    );
  }
}

// ── Reusable Coin Icon (matching React ProductCoinMark) ──
class _CoinIcon extends StatelessWidget {
  final bool isSilver;
  final double size;
  const _CoinIcon({required this.isSilver, required this.size});

  @override
  Widget build(BuildContext context) {
    final innerSize = (size - 8).clamp(34.0, size);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSilver ? const Color(0xFF1D2530) : const Color(0xFF1A1408),
        border: Border.all(color: isSilver ? const Color(0xFF7388A5) : const Color(0xFFB28A3B), width: 1),
      ),
      child: Center(
        child: Container(
          width: innerSize, height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSilver ? const Color(0xFF0D1117) : const Color(0xFF0D0902),
          ),
          alignment: Alignment.center,
          child: Text(
            'KARATLY',
            style: TextStyle(fontSize: size * 0.18, fontWeight: FontWeight.w600, letterSpacing: 0.08, color: isSilver ? Colors.white : const Color(0xFFF7CD57)),
          ),
        ),
      ),
    );
  }
}
