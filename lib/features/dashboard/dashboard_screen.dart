import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:karatly/core/services/rate_provider.dart';
import 'package:karatly/core/services/home_provider.dart';
import 'package:karatly/core/services/orders_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _portfolioToggle = 'Quarterly';
  String _investmentToggle = 'Monthly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).fetchInvestmentData();
      ref.read(ordersProvider.notifier).fetchAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rateState = ref.watch(rateProvider);
    final home = ref.watch(homeProvider);
    final orders = ref.watch(ordersProvider);

    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;

    final investment = home.investment;
    final goldInvested = investment.goldTotalInvested;
    final silverInvested = investment.silverTotalInvested;
    final totalInvested = investment.totalInvested;
    final portfolioValue = investment.goldHoldingWithMultiplier * goldRate
        + investment.silverHoldingWithMultiplier * silverRate;

    final allOrders = orders.orders;
    final recentOrders = allOrders.take(5).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9755, -0.3792),
          radius: 1.04,
          colors: [Color(0xFF4A3A1E), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(goldRate: goldRate, silverRate: silverRate),
              const SizedBox(height: 16),
              _buildWelcomeCard(totalInvested: totalInvested, portfolioValue: portfolioValue),
              const SizedBox(height: 24),
              _buildPortfolioGrowth(home: home),
              const SizedBox(height: 24),
              _buildPortfolioMixAndMarketRate(
                goldInvested: goldInvested,
                silverInvested: silverInvested,
                goldRate: goldRate,
                silverRate: silverRate,
              ),
              const SizedBox(height: 24),
              _buildSipManagement(),
              const SizedBox(height: 24),
              _buildAssetAllocation(
                goldInvested: goldInvested,
                silverInvested: silverInvested,
                goldRate: goldRate,
                silverRate: silverRate,
              ),
              const SizedBox(height: 24),
              _buildInvestmentPerformance(home: home),
              const SizedBox(height: 24),
              _buildRecentOrders(orders: recentOrders),
              const SizedBox(height: 24),
              _buildRewardsBenefits(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar({required double goldRate, required double silverRate}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFF5C953), Color(0xFFB98324)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('K',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF7CD57),
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Karatly',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text('PREMIUM GOLD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.05,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
          const Spacer(),
          _LiveRatePill(
            label: 'Gold',
            rate: goldRate,
            color: const Color(0xFFF7CD57),
          ),
          const SizedBox(width: 8),
          _LiveRatePill(
            label: 'Silver',
            rate: silverRate,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // ─── Welcome Back Card ────────────────────────────────────────────────────

  Widget _buildWelcomeCard({required double totalInvested, required double portfolioValue}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF110D09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome Back',
            style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
          ),
          const SizedBox(height: 4),
          const Text('INVESTOR',
            style: TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Portfolio is Growing! Track, Invest & Grow your Wealth with Karatly',
            style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox(label: 'Total Portfolio Value', value: _formatCurrency(portfolioValue)),
              const SizedBox(width: 12),
              _buildStatBox(label: 'Total Invested Value', value: _formatCurrency(totalInvested)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value, Color? valueColor}) {
    return Expanded(
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFC9C9C9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
              style: const TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(value,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Portfolio Growth ─────────────────────────────────────────────────────

  Widget _buildPortfolioGrowth({required HomeState home}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF110D09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Portfolio Growth',
                    style: TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text('Inclusive of all assets Classes',
                    style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
                  ),
                ],
              ),
              _buildToggle(
                left: 'Quarterly',
                right: 'Yearly',
                selected: _portfolioToggle,
                onChanged: (v) => setState(() => _portfolioToggle = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder(height: 170, yLabels: ['14.0 L', '10.5 L', '7.0 L', '3.5 L', '0.0 L']),
        ],
      ),
    );
  }

  // ─── Portfolio Mix & Market Rate Snapshot ─────────────────────────────────

  Widget _buildPortfolioMixAndMarketRate({
    required double goldInvested,
    required double silverInvested,
    required double goldRate,
    required double silverRate,
  }) {
    final total = goldInvested + silverInvested;
    final goldPct = total > 0 ? (goldInvested / total * 100).round() : 0;
    final silverPct = total > 0 ? (silverInvested / total * 100).round() : 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPortfolioMix(
          goldPct: goldPct,
          silverPct: silverPct,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildMarketRateSnapshot(
          goldRate: goldRate,
          silverRate: silverRate,
        )),
      ],
    );
  }

  Widget _buildPortfolioMix({required int goldPct, required int silverPct}) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF110D09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Portfolio Mix',
            style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFF7CD57),
                          const Color(0xFF917833),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF110D09),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(color: const Color(0xFFF7CD57), label: 'Gold $goldPct%'),
          _buildLegendItem(color: Colors.white, label: 'Silver $silverPct%'),
          _buildLegendItem(color: const Color(0xFF0084FF), label: 'Diamond 0%'),
          _buildLegendItem(color: const Color(0xFF9747FF), label: 'Jewellery 0%'),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
            style: const TextStyle(fontFamily: 'Lato', fontSize: 8, fontWeight: FontWeight.w400, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketRateSnapshot({required double goldRate, required double silverRate}) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF110D09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Rate Snapshot',
            style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildRateRow(label: 'Gold Rate', value: '₹${goldRate.toStringAsFixed(2)} /gm'),
          _buildRateRow(label: 'Silver Rate', value: '₹${silverRate.toStringAsFixed(2)} /gm'),
          const _ComingSoonRateRow(label: 'Diamond Rate'),
        ],
      ),
    );
  }

  Widget _buildRateRow({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F0C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E6E6E), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Lato', fontSize: 8, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SIP Management ───────────────────────────────────────────────────────

  Widget _buildSipManagement() {
    return Opacity(
      opacity: 0.5,
      child: AbsorbPointer(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF110D09), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4E4E4E))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('SIP Management', style: TextStyle(fontFamily: 'Alegreya', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Coming Soon', style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9))),
              const SizedBox(height: 16),
              _buildChartPlaceholder(height: 170, yLabels: ['', '', '', '', '']),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Asset Allocation ─────────────────────────────────────────────────────

  Widget _buildAssetAllocation({
    required double goldInvested,
    required double silverInvested,
    required double goldRate,
    required double silverRate,
  }) {
    final goldValue = double.tryParse(goldInvested.toString()) ?? goldInvested;
    final silverValue = double.tryParse(silverInvested.toString()) ?? silverInvested;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Asset Allocation',
          style: TextStyle(fontFamily: 'Alegreya', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text('Distribution across precious assets',
          style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAssetCard(
              title: 'Digital Gold Invested',
              holdingsLabel: 'Total Gold Holdings',
              holdingsValue: '${goldInvested.toStringAsFixed(2)} gm',
              value: _formatCurrency(goldValue),
              buttonText: 'Buy Gold',
              onTap: () => context.go('/buy/buy/1?metal=gold'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildAssetCard(
              title: 'Digital Silver Invested',
              holdingsLabel: 'Total Silver Holdings',
              holdingsValue: '${silverInvested.toStringAsFixed(2)} gm',
              value: _formatCurrency(silverValue),
              buttonText: 'Buy Silver',
              onTap: () => context.go('/buy/buy/1?metal=silver'),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildAssetCard(
              title: 'Diamond purchased',
              holdingsLabel: 'Coming Soon',
              holdingsValue: '--',
              value: '₹0',
              buttonText: 'Coming Soon',
              onTap: () {},
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildAssetCard(
              title: 'Jewellery purchased',
              holdingsLabel: 'Coming Soon',
              holdingsValue: '--',
              value: '₹0',
              buttonText: 'Coming Soon',
              onTap: () {},
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildAssetCard({
    required String title,
    required String holdingsLabel,
    required String holdingsValue,
    required String value,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF110D09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
            style: const TextStyle(fontFamily: 'Alegreya', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(holdingsLabel,
            style: const TextStyle(fontFamily: 'Lato', fontSize: 9, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
          ),
          Text(holdingsValue,
            style: const TextStyle(fontFamily: 'Lato', fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Flexible(child: Text(value, style: const TextStyle(fontFamily: 'Lato', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF4C4C4C),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFC9C9C9), width: 0.5),
              ),
              child: Center(
                child: Text(buttonText,
                  style: const TextStyle(fontFamily: 'Lato', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Investment Performance ───────────────────────────────────────────────

  Widget _buildInvestmentPerformance({required HomeState home}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF110D09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Investment Performance',
                    style: TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text('Deep analytics across your Portfolio',
                    style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
                  ),
                ],
              ),
              _buildToggle(
                left: 'Monthly',
                right: 'Yearly',
                selected: _investmentToggle,
                onChanged: (v) => setState(() => _investmentToggle = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder(height: 170, yLabels: ['14.0 L', '10.5 L', '7.0 L', '3.5 L', '0.0 L']),
        ],
      ),
    );
  }

  // ─── Recent Orders ────────────────────────────────────────────────────────

  Widget _buildRecentOrders({required List orders}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Orders & Transactions',
          style: TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text('Your last ${orders.length} transactions',
          style: const TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF110D09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4E4E4E)),
          ),
          child: orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No recent orders',
                      style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Color(0xFFC9C9C9)),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableHeader(),
                      ...orders.map<Widget>((order) => _buildOrderRow(
                        orderId: order.id,
                        product: '${order.type} ${order.metalType}',
                        category: _getCategory(order),
                        amount: _formatCurrency(order.amount),
                        date: _formatDate(order.date),
                        status: order.status,
                        statusColor: _getStatusColor(order.status),
                      )),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          SizedBox(width: 80, child: Text('ORDER', style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF1F1F1)))),
          SizedBox(width: 140),
          Text('PRODUCT', style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF1F1F1))),
          SizedBox(width: 30),
          Text('CATEGORY', style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF1F1F1))),
          SizedBox(width: 30),
          Text('AMOUNT', style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF1F1F1))),
          SizedBox(width: 30),
          Text('DATE', style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF1F1F1))),
          SizedBox(width: 30),
          Text('STATUS', style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF1F1F1))),
        ],
      ),
    );
  }

  Widget _buildOrderRow({
    required String orderId,
    required String product,
    required String category,
    required String amount,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2E2D2A), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(orderId, style: const TextStyle(fontFamily: 'Lato', fontSize: 12, color: Color(0xFFC9C9C9)))),
          const SizedBox(width: 140),
          SizedBox(width: 120, child: Text(product, style: const TextStyle(fontFamily: 'Lato', fontSize: 12, color: Color(0xFFC9C9C9)))),
          const SizedBox(width: 30),
          SizedBox(width: 60, child: Text(category, style: const TextStyle(fontFamily: 'Lato', fontSize: 12, color: Color(0xFFC9C9C9)))),
          const SizedBox(width: 30),
          SizedBox(width: 70, child: Text(amount, style: const TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC9C9C9)))),
          const SizedBox(width: 30),
          SizedBox(width: 80, child: Text(date, style: const TextStyle(fontFamily: 'Lato', fontSize: 12, color: Color(0xFFC9C9C9)))),
          const SizedBox(width: 30),
          SizedBox(width: 70, child: Text(status, style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold, color: statusColor))),
        ],
      ),
    );
  }

  // ─── Rewards & Benefits ───────────────────────────────────────────────────

  Widget _buildRewardsBenefits() {
    return Opacity(
      opacity: 0.5,
      child: AbsorbPointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Rewards & Benefits', style: TextStyle(fontFamily: 'Alegreya', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.lock, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Exclusive privileges curated for members', style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF110D09),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC9C9C9)),
              ),
              child: Column(
                children: [
                  Container(width: 50, height: 50, decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Icon(Icons.workspace_premium, size: 50, color: Color(0xFFF7CD57))),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFD59D00)]).createShader(bounds),
                    child: const Text('GOLD MEMBER', style: TextStyle(fontFamily: 'Alegreya', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildRewardBox(label: 'Loyalty Points', value: '0 pts')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRewardBox(label: 'Referral Earnings', value: '₹0.00')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF323232), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Locked', style: TextStyle(fontFamily: 'Lato', fontSize: 10, color: Colors.grey)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardBox({required String label, required String value}) {
    return Container(
      height: 50, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF323232), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF9E9E9E))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Lato', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFC9C9C9))),
          Text(value, style: const TextStyle(fontFamily: 'Lato', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white38)),
        ],
      ),
    );
  }

  // ─── Shared Toggle Widget ─────────────────────────────────────────────────

  Widget _buildToggle({
    required String left,
    required String right,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: 100,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF403A30),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF9E9E9E)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: selected == left ? 0 : 50,
            top: 0,
            bottom: 0,
            width: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(1.25, 0.29),
                  end: Alignment(-0.45, 0.55),
                  colors: [Color(0xFFFED55C), Color(0xFFDA9500)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(left),
                  child: Center(
                    child: Text(left,
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 8,
                        fontWeight: selected == left ? FontWeight.bold : FontWeight.w400,
                        color: selected == left ? Colors.black : const Color(0xFFC9C9C9),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(right),
                  child: Center(
                    child: Text(right,
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 8,
                        fontWeight: selected == right ? FontWeight.bold : FontWeight.w400,
                        color: selected == right ? Colors.black : const Color(0xFFC9C9C9),
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '--';
    try {
      final dt = DateTime.parse(timestamp);
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;
    }
  }

  String _getCategory(dynamic order) {
    final metal = (order.metalType ?? '').toLowerCase();
    if (metal.contains('gold')) return 'Gold';
    if (metal.contains('silver')) return 'Silver';
    if (metal.contains('diamond')) return 'Diamond';
    return 'Gold';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF15EE01);
      case 'processing':
      case 'pending':
        return const Color(0xFFFF9500);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFEE0105);
      default:
        return const Color(0xFFFF9500);
    }
  }

  // ─── Chart Placeholder ────────────────────────────────────────────────────

  Widget _buildChartPlaceholder({required double height, required List<String> yLabels}) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: yLabels.map((label) => Text(label,
              style: const TextStyle(fontFamily: 'Lato', fontSize: 6, color: Color(0xFFC9C9C9)),
            )).toList(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Rate Pill ───────────────────────────────────────────────────────

class _LiveRatePill extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;

  const _LiveRatePill({
    required this.label,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7CD57), Color(0xFFB98324)],
              ),
            ),
            child: const Center(
              child: Text('K', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            rate > 0 ? '₹${rate.toStringAsFixed(2)}' : '--',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Coming Soon Rate Row ─────────────────────────────────────────────────

class _ComingSoonRateRow extends StatelessWidget {
  final String label;
  const _ComingSoonRateRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F0C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E6E6E), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(fontFamily: 'Lato', fontSize: 8, fontWeight: FontWeight.w400, color: Color(0xFFC9C9C9)),
                ),
                const SizedBox(height: 2),
                const Text('Coming Soon',
                  style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Painter ────────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF787878)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dashedPaint = Paint()
      ..color = const Color(0xFF787878)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), dashedPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFF7CD57)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.1, size.height * 0.75),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.3, size.height * 0.65),
      Offset(size.width * 0.4, size.height * 0.45),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.35),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.15),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF7CD57).withValues(alpha: 0.3),
          Colors.black.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFF7CD57)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(60)),
      borderPaint,
    );

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < months.length; i++) {
      final x = (size.width / (months.length - 1)) * i;
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(fontFamily: 'Lato', fontSize: 6, color: Color(0xFFC9C9C9)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, size.height + 4));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final double dashWidth = 5;
    final double dashSpace = 5;
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = (dx * dx + dy * dy) > 0 ? (end - start).distance : 0;
    final double dashes = distance / (dashWidth + dashSpace);

    for (double i = 0; i < dashes; i++) {
      final double x = start.dx + (dx * i / dashes);
      final double y = start.dy + (dy * i / dashes);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dx / dashes * (dashWidth / (dashWidth + dashSpace)), y + dy / dashes * (dashWidth / (dashWidth + dashSpace))),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
