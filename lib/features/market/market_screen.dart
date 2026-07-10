import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/models/gold_rate_model.dart';
import '../../core/services/market_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/models/product_model.dart';

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
    final borderColor = isSilver ? const Color(0xFF7388A5) : const Color(0xFFB28A3B);
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
        Row(
          children: [
            Icon(Icons.arrow_back_ios_new_rounded, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Market',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accentColor),
            ),
          ],
        ),
        Container(
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
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isSilver
              ? [const Color(0xFF495C73), const Color(0xFF0D1117)]
              : [panelBg, Colors.black],
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
          color: isSelected ? accentColor : Colors.transparent,
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
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: isSilver ? Colors.white : const Color(0xFFF7CD57)),
        ),
      );
    }

    if (market.chartData.isEmpty) {
      return SizedBox(
        height: 200,
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
    final minY = allValues.isEmpty ? 0.0 : (allValues.reduce(math.min) * 0.995);
    final maxY = allValues.isEmpty ? 100.0 : (allValues.reduce(math.max) * 1.005);

    return Container(
      height: 200,
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
                  final label = data[idx].label;
                  final shortLabel = label.length > 5 ? label.substring(5) : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      shortLabel,
                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
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
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: isSilver
                ? [Colors.white, Colors.grey[400]!]
                : [const Color(0xFFFED45C), const Color(0xFFDB9502)],
          ),
        ),
        child: Stack(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.transparent,
              highlightColor: Colors.white.withValues(alpha: 0.3),
              period: const Duration(milliseconds: 2500),
              child: Container(
                width: 20,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Colors.white60, Colors.transparent],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSilver ? 'BUY SILVER NOW' : 'BUY GOLD NOW',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        'Secure · Fast · Trusted',
                        style: TextStyle(fontSize: 10, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required MarketState market,
    required bool isSilver,
    required Color borderColor,
  }) {
    return Column(
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
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF2A2520),
          highlightColor: const Color(0xFF3D3B37),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1710),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4E4E4E)),
            ),
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
class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSilver;

  const _ProductCard({required this.product, required this.isSilver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1710),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Row(
        children: [
          _buildCoinIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.purity} | ${product.productWeight.isNotEmpty ? product.productWeight : product.redeemWeight}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                _buildRedeemButton(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            product.status,
            style: const TextStyle(fontSize: 12, color: Color(0xFF15EE01)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSilver
              ? [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)]
              : [const Color(0xFFF7CD57), const Color(0xFFE5AF35)],
        ),
      ),
      child: Center(
        child: Text(
          isSilver ? 'Ag' : 'Au',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSilver ? Colors.black : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isSilver
              ? [Colors.white, Colors.grey[400]!]
              : [const Color(0xFFF7CD57), const Color(0xFFE5AF35)],
        ),
      ),
      child: const Text(
        'Tap to redeem',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
