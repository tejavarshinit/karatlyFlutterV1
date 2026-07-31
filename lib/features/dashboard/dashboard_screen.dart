import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/home_provider.dart';
import '../../core/services/orders_provider.dart';
import '../../core/services/auth_provider.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _chartPeriod = 'Quarterly';

  @override
  void initState() {
    super.initState();
    debugPrint('[FLOW] DashboardScreen.initState | fetching investment + orders');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).fetchInvestmentData();
      ref.read(ordersProvider.notifier).fetchAllOrders();
    });
  }

  List<double> get _chartPoints => _chartPeriod == 'Quarterly'
      ? [10,15,12,20,18,25,22,30,35,28,40,38,45,50,48,55,60,58,65,70]
      : [10,12,18,22,30,35,40,50,55,60,70,80,90,100,110,125,140,150,160,175];

  String _formatCurrency(double amount) {
    final fmt = NumberFormat.currency(symbol: 'Rs.', locale: 'en_IN', decimalDigits: 2);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final rateState = ref.watch(rateProvider);
    final home = ref.watch(homeProvider);
    final orders = ref.watch(ordersProvider);
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? auth.fullName ?? 'User';

    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;
    final investment = home.investment;

    final goldValue = investment.goldHoldingWithMultiplier * goldRate;
    final silverValue = investment.silverHoldingWithMultiplier * silverRate;
    final portfolioValue = goldValue + silverValue;
    final totalInvested = investment.totalInvested;

    debugPrint('[FLOW] Dashboard build | goldHoldings=${investment.goldHoldingWithMultiplier} silverHoldings=${investment.silverHoldingWithMultiplier} goldRate=$goldRate silverRate=$silverRate portfolioValue=$portfolioValue');

    final recentOrders = orders.orders.take(3).toList();

    // Portfolio mix
    final totalMix = portfolioValue > 0 ? portfolioValue : 1;
    final goldPct = portfolioValue > 0 ? (goldValue / totalMix) * 100 : 0.0;
    final silverPct = portfolioValue > 0 ? (silverValue / totalMix) * 100 : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9755, -0.3792),
          radius: 1.04,
          colors: [Color(0xFF2A1E06), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(goldRate: goldRate, silverRate: silverRate),
              const SizedBox(height: 12),
              _buildWelcomeCard(userName: userName, portfolioValue: portfolioValue, totalInvested: totalInvested),
              const SizedBox(height: 16),
              _buildAssetAllocation(investment: investment, goldRate: goldRate, silverRate: silverRate),
              const SizedBox(height: 16),
              _buildPortfolioGrowth(),
              const SizedBox(height: 16),
              _buildSipManagement(),
              const SizedBox(height: 16),
              _buildPortfolioMixAndMarketRate(goldRate: goldRate, silverRate: silverRate, goldPct: goldPct, silverPct: silverPct),
              const SizedBox(height: 16),
              _buildRecentOrders(recentOrders: recentOrders),
              const SizedBox(height: 16),
              _buildRewardsBenefits(),
              const SizedBox(height: 16),
              _buildFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. HEADER ──
  Widget _buildHeader({required double goldRate, required double silverRate}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Image.asset('assets/images/KaratlyLOGO-removebg-preview.png', width: 36, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Karatly', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('PREMIUM GOLD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.12, color: Color(0xFFC9A84C))),
          ]),
          const Spacer(),
          _AnimatedLiveRatePill(metal: 'gold', price: goldRate),
          const SizedBox(width: 4),
          _AnimatedLiveRatePill(metal: 'silver', price: silverRate),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.go(AppRoutes.notifications),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1408), border: Border.all(color: const Color(0xFF4E4E4E))),
              child: const Icon(Icons.notifications_outlined, size: 13, color: Color(0xFFC1C1C1)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. WELCOME CARD ──
  Widget _buildWelcomeCard({required String userName, required double portfolioValue, required double totalInvested}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1E06), Color(0xFF1A1208), Color(0xFF0D0902)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4E4E4E)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Welcome back,', style: TextStyle(fontSize: 16, color: Color(0xFFA1A1A1))),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35)]).createShader(bounds),
                    child: Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Your Portfolio is Growing!\nTrack, Invest & Grow your Wealth with Karatly',
                      style: TextStyle(fontSize: 10, color: Color(0xFFBCBCBC))),
                ])),
                SizedBox(
                  width: 90, height: 73,
                  child: Image.asset('assets/images/JewelleryDashboard.png', fit: BoxFit.contain),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                Expanded(child: _statBox('Total Portfolio Value', _formatCurrency(portfolioValue), const Color(0xFFF7CD57))),
                const SizedBox(width: 8),
                Expanded(child: _statBox('Total Invested Value', _formatCurrency(totalInvested), const Color(0xFFF7CD57))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4E4E4E))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFBCBCBC))),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor, fontFamily: 'Poppins'))),
      ]),
    );
  }

  // ── 3. ASSET ALLOCATION ──
  Widget _buildAssetAllocation({required InvestmentData investment, required double goldRate, required double silverRate}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Asset Allocation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text('Distribution across precious assets', style: TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _assetCard(
            title: 'Digital Gold Invested', subtitle: 'Total Gold Holdings',
            holding: '${investment.goldHoldingWithMultiplier.toStringAsFixed(4)}/gm',
            value: 'Rs.${NumberFormat('#,##,###', 'en_IN').format(investment.goldTotalInvested.toInt())}',
            btnLabel: 'Buy Gold', isLocked: false,
            onTap: () => context.go('/buy-gold/select?metal=gold'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _assetCard(
            title: 'Digital Silver Invested', subtitle: 'Total Silver Holdings',
            holding: '${investment.silverHoldingWithMultiplier.toStringAsFixed(4)}/gm',
            value: 'Rs.${NumberFormat('#,##,###', 'en_IN').format(investment.silverTotalInvested.toInt())}',
            btnLabel: 'Buy Silver', isLocked: false,
            onTap: () => context.go('/buy-gold/select?metal=silver'),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _assetCard(
            title: 'Diamond Purchase', subtitle: '', holding: '', value: '',
            btnLabel: 'Diamond', isLocked: false,
            onTap: () => context.go(AppRoutes.home, extra: {'metalType': 'diamond'}),
          )),
          const SizedBox(width: 12),
          Expanded(child: _assetCard(
            title: 'Jewellery purchased', subtitle: '', holding: '', value: '',
            btnLabel: 'Jewellery', isLocked: true, onTap: null,
          )),
        ]),
      ]),
    );
  }

  Widget _assetCard({required String title, String subtitle = '', String holding = '', String value = '', required String btnLabel, required bool isLocked, VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111008),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4E4E4E)),
      ),
      child: Stack(children: [
        if (isLocked)
          Positioned(right: 8, top: 8, child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1408), border: Border.all(color: const Color(0xFF4E4E4E))),
            child: const Icon(Icons.lock, size: 12, color: Color(0xFFF7CD57)),
          )),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF7E7E7E))),
          ],
          if (holding.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(holding, style: const TextStyle(fontSize: 8, color: Color(0xFF9E9E9E))),
          ],
          if (value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isLocked ? null : onTap,
            child: Container(
              width: double.infinity, height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: isLocked ? null : const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFD09B14)]),
                color: isLocked ? const Color(0xFF2A2010) : null,
                border: isLocked ? Border.all(color: const Color(0xFF4E4E4E)) : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (isLocked) ...[const Icon(Icons.lock, size: 10, color: Color(0xFF7E7E7E)), const SizedBox(width: 4)],
                Text(btnLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isLocked ? const Color(0xFF7E7E7E) : Colors.black)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── 4. PORTFOLIO GROWTH ──
  Widget _buildPortfolioGrowth() {
    return _chartCard(
      title: 'Portfolio Growth',
      subtitle: 'Inclusive of all assets Classes',
      points: _chartPoints,
      chartHeight: 80,
      period: _chartPeriod,
      onToggle: (v) => setState(() => _chartPeriod = v),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required List<double> points, required double chartHeight, required String period, required ValueChanged<String> onToggle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF111008), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
            ]),
            _toggleBtn(period, onToggle),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                size: Size(double.infinity, chartHeight),
                painter: _AreaChartPainter(points: points, chartWidth: 330, chartHeight: chartHeight),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _toggleBtn(String current, ValueChanged<String> onChanged) {
    return Container(
      height: 24,
      decoration: BoxDecoration(color: const Color(0xFF1E1A0E), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF4E4E4E))),
      child: Row(children: [
        _toggleOption('Quarterly', current, onChanged),
        _toggleOption('Yearly', current, onChanged),
      ]),
    );
  }

  Widget _toggleOption(String value, String current, ValueChanged<String> onChanged) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: active ? const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFD09B14)]) : null,
        ),
        child: Center(child: Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? Colors.black : const Color(0xFF7E7E7E)))),
      ),
    );
  }

  // ── 5. SIP MANAGEMENT ──
  Widget _buildSipManagement() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF111008), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Stack(children: [
              Positioned(right: 8, top: 8, child: _lockIcon()),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SIP Management', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Disciplined wealth building, automated', style: TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFF1A1408), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4E4E4E))),
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Active SIP Plans', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('3 active / Next debit on 15 Jun 2026', style: TextStyle(fontSize: 8, color: Color(0xFF7E7E7E))),
                      ]),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _lockedBtn('Start New SIP')),
                  const SizedBox(width: 8),
                  Expanded(child: _lockedBtn('Manage SIP')),
                  const SizedBox(width: 8),
                  Expanded(child: _lockedBtn('View Statement')),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _lockedBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF2A2010), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF4E4E4E))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock, size: 10, color: Color(0xFF7E7E7E)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
      ]),
    );
  }

  Widget _lockIcon() {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(color: const Color(0xFF1A1408), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4E4E4E))),
      child: const Icon(Icons.lock, size: 12, color: Color(0xFFF7CD57)),
    );
  }

  // ── 6. PORTFOLIO MIX + MARKET RATE SNAPSHOT ──
  Widget _buildPortfolioMixAndMarketRate({required double goldRate, required double silverRate, required double goldPct, required double silverPct}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _buildPortfolioMix(goldPct: goldPct, silverPct: silverPct)),
        const SizedBox(width: 12),
        Expanded(child: _buildMarketRateSnapshot(goldRate: goldRate, silverRate: silverRate)),
      ]),
    );
  }

  Widget _buildPortfolioMix({required double goldPct, required double silverPct}) {
    final r = 40.0; final circ = 2 * math.pi * r;
    final goldDash = (goldPct / 100) * circ;
    final silverDash = (silverPct / 100) * circ;
    final sOff = -goldDash;

    return Container(
      decoration: BoxDecoration(color: const Color(0xFF111008), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Portfolio Mix', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        SizedBox(
          width: 90, height: 90,
          child: Center(
            child: CustomPaint(
              size: const Size(90, 90),
              painter: _DonutChartPainter(goldPct: goldPct, silverPct: silverPct),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legendRow(const Color(0xFFF7CD57), 'Gold', '${goldPct.toStringAsFixed(1)}%'),
        _legendRow(const Color(0xFFC0C0C0), 'Silver', '${silverPct.toStringAsFixed(1)}%'),
      ]),
    );
  }

  Widget _legendRow(Color color, String label, String pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E))),
        const Spacer(),
        Text(pct, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  Widget _buildMarketRateSnapshot({required double goldRate, required double silverRate}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF111008), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Market Rate Snapshot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        _marketRateRow('Gold Rate', goldRate > 0 ? 'Rs.${NumberFormat('#,##,###', 'en_IN').format(goldRate.round())}/gm' : 'Loading...'),
        const SizedBox(height: 8),
        _marketRateRow('Silver Rate', silverRate > 0 ? 'Rs.${silverRate.toStringAsFixed(2)}/gm' : 'Loading...'),
      ]),
    );
  }

  Widget _marketRateRow(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF7E7E7E))),
      Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis),
    ]);
  }

  // ── 7. RECENT ORDERS ──
  Widget _buildRecentOrders({required List recentOrders}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF111008), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Recent Orders & Transactions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Your last 3 transactions', style: TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4E4E4E))),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(color: Color(0xFF1A1408)),
                child: const Row(children: [
                  Expanded(flex: 3, child: Text('TXN ID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E)))),
                  Expanded(flex: 3, child: Text('TYPE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E)))),
                  Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E)), textAlign: TextAlign.end)),
                ]),
              ),
              if (recentOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF0D0902),
                  child: const Center(child: Text('No transactions yet', style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)))),
                )
              else
                ...List.generate(recentOrders.length, (i) {
                  final o = recentOrders[i];
                  final isSell = o.type.toString().toUpperCase() == 'SELL';
                  final mt = o.metalType?.toString().toLowerCase() ?? '';
                  final isDiamond = mt == 'diamond';
                  final metalLabel = isDiamond ? 'Diamond' : (mt == 'silver' ? 'Silver' : 'Gold');
                  final txnId = (o.merchantTransactionId ?? o.transactionId ?? o.id ?? '').toString();
                  final bg = i % 2 == 0 ? const Color(0xFF0D0902) : const Color(0xFF111008);
                  return Container(
                    decoration: BoxDecoration(color: bg, border: Border(top: BorderSide(color: const Color(0xFF1E1A0E)))),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text(txnId.length > 8 ? '...${txnId.substring(txnId.length - 8)}' : txnId,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFF7CD57)), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 3, child: Row(children: [
                        Text(metalLabel, style: const TextStyle(fontSize: 9, color: Colors.white)),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: o.type.toString().toUpperCase() == 'REDEEM' ? const Color(0xFF242C36) : (isSell ? const Color(0xFF243736) : const Color(0xFF38342C)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(o.type.toString().toUpperCase(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold,
                              color: o.type.toString().toUpperCase() == 'REDEEM' ? Colors.white : (isSell ? const Color(0xFF6DD6FF) : const Color(0xFFF7CD57)))),
                        ),
                      ])),
                      Expanded(flex: 2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text('Rs.${o.amount?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)))),
                    ]),
                  );
                }),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── 8. REWARDS & BENEFITS ──
  Widget _buildRewardsBenefits() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Opacity(
        opacity: 0.6,
        child: AbsorbPointer(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
            child: Column(children: [
              Stack(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  decoration: const BoxDecoration(color: Color(0xFF111008)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rewards & Benefits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Exclusive privileges curated for members', style: TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
                  ]),
                ),
                Positioned(right: 8, top: 8, child: _lockIcon()),
              ]),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  gradient: RadialGradient(center: Alignment(0.5, 0.0), radius: 0.8, colors: [Color(0xFF3A2A04), Color(0xFF0D0902)]),
                ),
                child: Column(children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(center: Alignment(0.35, 0.3), colors: [Color(0xFFFFE27A), Color(0xFFF5BF31), Color(0xFFC98900)]),
                    ),
                    child: Center(
                      child: Image.asset('assets/images/GOLDCOINDASHBOARD.png', width: 60, height: 60, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35)]).createShader(bounds),
                    child: const Text('GOLD MEMBER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(child: _rewardBox('Loyalty Points', '0', 'pts')),
                      const SizedBox(width: 12),
                      Expanded(child: _rewardBox('Referral Earnings', 'Rs.0', '')),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _rewardBox(String label, String value, String suffix) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1408), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4E4E4E))),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        if (suffix.isNotEmpty) Text(suffix, style: const TextStyle(fontSize: 8, color: Color(0xFFC9A84C))),
      ]),
    );
  }

  // ── 9. FOOTER ──
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF111008), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4E4E4E))),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35)]).createShader(bounds),
              child: const Text('Karatly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const Text(' | ', style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
            const Text('Digital Gold & Silver', style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 8, alignment: WrapAlignment.center, children: [
            _footerLink('Privacy Policy', AppRoutes.privacyPolicy),
            _footerLink('Refund Policy', AppRoutes.refundPolicy),
            _footerLink('Terms', AppRoutes.terms),
            _footerLink('Terms of Use', AppRoutes.termsOfUse),
            _footerLink('Trademark Notice', AppRoutes.trademarkNotice),
            _footerLink('How It Works', AppRoutes.howItWorks),
            _footerLink('Why Karatly', AppRoutes.why),
          ]),
          const Divider(color: Color(0xFF2A2010), height: 24),
          Text('© ${DateTime.now().year} Karatly. All rights reserved.', style: const TextStyle(fontSize: 8, color: Color(0xFF5E5E5E))),
          const SizedBox(height: 4),
          const Text('Powered by Augmont • Backed by SafeGold', style: TextStyle(fontSize: 8, color: Color(0xFF5E5E5E))),
        ]),
      ),
    );
  }

  Widget _footerLink(String label, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), decoration: TextDecoration.underline)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED LIVE RATE PILL
// ═══════════════════════════════════════════════════════════════

class _AnimatedLiveRatePill extends StatefulWidget {
  final String metal;
  final double price;
  const _AnimatedLiveRatePill({required this.metal, required this.price});

  @override
  State<_AnimatedLiveRatePill> createState() => _AnimatedLiveRatePillState();
}

class _AnimatedLiveRatePillState extends State<_AnimatedLiveRatePill> with TickerProviderStateMixin {
  late AnimationController _wiggleCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _wiggleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat();
  }

  @override
  void dispose() {
    _wiggleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGold = widget.metal == 'gold';
    final label = isGold ? 'Gold' : 'Silver';
    final value = widget.price > 0 ? 'Rs.${NumberFormat('#,##,###', 'en_IN').format(widget.price.round())}/g' : '...';

    return AnimatedBuilder(
      animation: _wiggleCtrl,
      builder: (context, child) {
        // Wiggle animation: rotate [-1.5, 1.5, 0] and y [0, -1, 0]
        final wiggleRotate = math.sin(_wiggleCtrl.value * 2 * math.pi) * 1.5;
        final wiggleY = -(math.sin(_wiggleCtrl.value * 2 * math.pi)).abs();

        return Transform.translate(
          offset: Offset(0, wiggleY),
          child: Transform.rotate(
            angle: wiggleRotate * (math.pi / 180),
            child: Container(
              height: 28, padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: isGold ? const Color(0x73E8B438) : const Color(0x61FFFFFF)),
                borderRadius: BorderRadius.circular(14),
                gradient: isGold
                    ? const LinearGradient(colors: [Color(0xFF3A2A04), Color(0xFF1A1408), Color(0xFF0D0902)])
                    : const LinearGradient(colors: [Color(0xFF3B4654), Color(0xFF171D24), Color(0xFF0D1117)]),
                boxShadow: [BoxShadow(color: (isGold ? const Color(0xFFF7CD57) : const Color(0xFFC6CDD7)).withValues(alpha: 0.1), blurRadius: 22)],
              ),
              child: Stack(
                children: [
                  // Shimmer sweep
                  Positioned(
                    left: -45, top: 0, bottom: 0,
                    child: AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shimmerCtrl.value * 310, 0),
                          child: Transform(
                            transform: Matrix4.identity()..setEntry(0, 1, math.tan(-0.32)),
                            child: Container(
                              width: 40, height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                                  colors: [Colors.transparent, Color(0x38FFFFFF), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isGold
                            ? const RadialGradient(colors: [Color(0xFFFFF1A6), Color(0xFFF7CD57), Color(0xFFB57F23)])
                            : const RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFC6CDD7), Color(0xFF7D8794)]),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isGold ? const Color(0xFFF7CD57) : const Color(0xFFE5EAF0))),
                    const SizedBox(width: 2),
                    Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHART PAINTERS
// ═══════════════════════════════════════════════════════════════

class _AreaChartPainter extends CustomPainter {
  final List<double> points;
  final double chartWidth;
  final double chartHeight;
  final Color lineColor;
  final double fillOpacity;

  _AreaChartPainter({
    required this.points,
    this.chartWidth = 330,
    this.chartHeight = 80,
    this.lineColor = const Color(0xFFF7CD57),
    this.fillOpacity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min).clamp(1, double.infinity);
    final w = chartWidth;
    final h = chartHeight;
    final xs = List.generate(points.length, (i) => (i / (points.length - 1)) * w);
    final ys = points.map((p) => h - ((p - min) / range) * (h - 10) - 5).toList();

    final areaPath = Path()..moveTo(xs[0], ys[0]);
    for (var i = 1; i < xs.length; i++) { areaPath.lineTo(xs[i], ys[i]); }
    areaPath..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(areaPath, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [lineColor.withValues(alpha: fillOpacity), lineColor.withValues(alpha: 0.02)],
    ).createShader(Rect.fromLTWH(0, 0, w, h)));

    final linePath = Path()..moveTo(xs[0], ys[0]);
    for (var i = 1; i < xs.length; i++) { linePath.lineTo(xs[i], ys[i]); }
    canvas.drawPath(linePath, Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter old) => old.points != points;
}

class _DonutChartPainter extends CustomPainter {
  final double goldPct, silverPct;

  _DonutChartPainter({required this.goldPct, required this.silverPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 32.0;
    const strokeWidth = 14.0;
    final total = goldPct + silverPct;
    if (total <= 0) return;

    final segments = [
      (pct: goldPct, color: const Color(0xFFF7CD57)),
      (pct: silverPct, color: const Color(0xFFC0C0C0)),
    ];

    const circ = 2 * math.pi * radius;
    final goldDash = (goldPct / 100) * circ;
    final silverDash = (silverPct / 100) * circ;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()..color = const Color(0xFF2A2010)..strokeWidth = strokeWidth..style = PaintingStyle.stroke,
    );

    // Gold arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, (goldPct / 100) * 2 * math.pi, false,
      Paint()..color = const Color(0xFFF7CD57)..strokeWidth = strokeWidth..style = PaintingStyle.stroke,
    );

    // Silver arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (goldPct / 100) * 2 * math.pi, (silverPct / 100) * 2 * math.pi, false,
      Paint()..color = const Color(0xFFC0C0C0)..strokeWidth = strokeWidth..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.goldPct != goldPct || old.silverPct != silverPct;
}
