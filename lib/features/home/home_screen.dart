import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/router.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/home_provider.dart';
import '../../core/services/orders_provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/models/augmont_model.dart';
import '../../core/models/diamond_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _metalType = 'gold';
  String _orderFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeProvider.notifier).fetchInvestmentData();
      ref.read(ordersProvider.notifier).fetchAllOrders();
    });
  }

  // ── Color helpers ──
  bool get _isGold => _metalType == 'gold';
  bool get _isSilver => _metalType == 'silver';
  bool get _isDiamond => _metalType == 'diamond';

  Color get _accentColor => _isDiamond ? const Color(0xFF3AC7FF) : _isSilver ? Colors.white : const Color(0xFFF7CD57);
  Color get _borderColor => _isDiamond ? const Color(0xFF05438B) : _isSilver ? const Color(0xFF495C73) : const Color(0xFFB28A3B);
  Color get _panelColor => _isDiamond ? const Color(0xFF0A1520) : _isSilver ? const Color(0xFF111821) : const Color(0xFF1A1710);
  Color get _badgeBg => _isDiamond ? const Color(0xFF0A2A3B) : _isSilver ? const Color(0xFF243736) : const Color(0xFF38342C);
  Color get _iconBg => _isDiamond ? const Color(0xFF0A2A3B) : _isSilver ? const Color(0xFF213435) : const Color(0xFF3D3214);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatGrams(double grams) {
    return '${grams.toStringAsFixed(4)}g';
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      final time = DateFormat('h:mm a').format(d);
      if (isToday) return 'Today · $time';
      final yesterday = now.subtract(const Duration(days: 1));
      if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Yesterday · $time';
      return '${DateFormat('MMM dd').format(d)} · $time';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rateState = ref.watch(rateProvider);
    final homeState = ref.watch(homeProvider);
    final ordersState = ref.watch(ordersProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.97, -0.38),
          radius: 1.04,
          colors: _isGold
              ? [const Color(0xFF4A3A1E), const Color(0xFF000000)]
              : _isSilver
                  ? [const Color(0xFF293341), const Color(0xFF000000)]
                  : [const Color(0xFF0A2A3B), const Color(0xFF000000)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(rateState),
                _buildPortfolioCard(rateState, homeState),
                _buildKycLimitBanner(rateState, homeState),
                _buildMetalTabs(),
                _buildQuickActions(),
                if (_isGold) _buildGoldCertificateSection(),
                if (!_isDiamond) _buildAssetOverview(rateState, homeState),
                _buildBuyNowButton(),
                _buildAIInsight(),
                _buildRecentTransactions(ordersState),
                const SizedBox(height: 16),
                _buildPoweredBy(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SECTION 1: Header ──
  Widget _buildHeader(RateState rateState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black),
            child: const Center(
              child: Text('K', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, color: Color(0xFFF7CD57), fontSize: 18)),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Karatly', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Playfair Display')),
              Text(
                _isGold ? 'PREMIUM GOLD' : _isSilver ? 'PREMIUM SILVER' : 'PREMIUM DIAMOND',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: _isGold ? const Color(0xFFC9A84C) : _isSilver ? const Color(0xFFE2E8F0) : const Color(0xFF4593F9),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Live rate pill
          if (!_isDiamond && rateState.currentRate != null)
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _isGold ? const Color(0xFF1D170D) : const Color(0xFF1D2530),
                  border: Border.all(color: _isGold ? const Color(0xFFE8B438) : const Color(0xFF7388A5), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF15EE01), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isGold
                          ? 'Gold Rs.${rateState.currentRate!.buyPrice.toStringAsFixed(2)}/g'
                          : 'Silver Rs.${rateState.currentRate!.silver.buyPrice.toStringAsFixed(2)}/g',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _accentColor),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Notification bell
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _isGold ? const Color(0xFFE8B438) : const Color(0xFF7388A5)), color: _isGold ? const Color(0xFF1D170D) : const Color(0xFF1D2530)),
            child: const Icon(Icons.notifications_outlined, size: 12, color: Color(0xFFC1C1C1)),
          ),
        ],
      ),
    );
  }

  // ── SECTION 2: Portfolio Hero Card ──
  Widget _buildPortfolioCard(RateState rateState, HomeState homeState) {
    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;
    final investment = homeState.investment;

    final portfolioValue = _isGold
        ? investment.goldHoldingWithMultiplier * goldRate
        : _isSilver
            ? investment.silverHoldingWithMultiplier * silverRate
            : investment.goldHoldingWithMultiplier * goldRate + investment.silverHoldingWithMultiplier * silverRate;

    final holdingGrams = _isSilver ? investment.silverHoldingWithMultiplier : investment.goldHoldingWithMultiplier;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
          gradient: LinearGradient(
            begin: const Alignment(2.44, 0.44),
            end: Alignment.topLeft,
            colors: _isGold
                ? [const Color(0xFF6C5123), const Color(0xFF1A1710)]
                : _isSilver
                    ? [const Color(0xFF495C73), const Color(0xFF0D1117)]
                    : [const Color(0xFF05438B), const Color(0xFF0D1117)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 16,
              top: 16,
              child: Opacity(opacity: 0.6, child: Text('KARATLY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _accentColor, letterSpacing: 2))),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isDiamond) ...[
                    const Text('PORTFOLIO VALUE', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Color(0xFFBCBCBC), fontFamily: 'Lato')),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rs.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.normal, color: _accentColor, fontFamily: 'Lato')),
                        const SizedBox(width: 4),
                        Text(
                          rateState.loading ? '...' : _formatCurrency(portfolioValue),
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _accentColor, fontFamily: 'Lato'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatGrams(holdingGrams)} ${_isSilver ? "Silver" : "Gold"} Holdings',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFBCBCBC), fontFamily: 'Lato'),
                    ),
                  ] else ...[
                    const Text('DIAMOND VAULT', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Color(0xFFBCBCBC), fontFamily: 'Lato')),
                    const SizedBox(height: 12),
                    Text(
                      'Invest in premium certified diamonds.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _accentColor, fontFamily: 'Lato'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Non-KYC Limit Banner ──

  Widget _buildKycLimitBanner(RateState rateState, HomeState homeState) {
    final authState = ref.watch(authProvider);
    final isKycVerified = authState.user?.kycApproved == true;
    if (isKycVerified) return const SizedBox.shrink();

    final investment = homeState.investment;
    final fyTotal = investment.goldTotalInvested + investment.silverTotalInvested;
    final availableLimit = (1000 - fyTotal).clamp(0, 1000);
    if (availableLimit <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GestureDetector(
        onTap: () => context.go('/kyc-verification'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _isSilver ? const Color(0x4DE2E8F0) : const Color(0x47E8B438)),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: _isSilver
                  ? [const Color(0xFF1D2530).withValues(alpha: 0.7), const Color(0xFF0D1117)]
                  : [const Color(0xFF2A1F0D), const Color(0xFF120D05)],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: _isSilver
                      ? const LinearGradient(colors: [Colors.white, Color(0xFF999999)])
                      : const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFC88912)])),
                child: const Icon(Icons.shield, size: 14, color: Color(0xFF15120B))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Non-KYC Purchase Limit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('₹${availableLimit.toInt()}  ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _isSilver ? const Color(0xFFF2F5F8) : const Color(0xFFF7CD57))),
              ])),
            ]),
            const SizedBox(height: 4),
            const Text('Complete KYC to unlock higher purchase limit.', style: TextStyle(fontSize: 8, color: Color(0xFFBDB5A5))),
            const SizedBox(height: 6),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _isSilver ? const Color(0x61E2E8F0) : const Color(0x6BF7CD57)),
                gradient: const LinearGradient(colors: [Color(0xFF2A210D), Color(0xFF120D05)]),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Complete KYC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _isSilver ? const Color(0xFFF2F5F8) : const Color(0xFFF7CD57))),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 11, color: _isSilver ? const Color(0xFFF2F5F8) : const Color(0xFFF7CD57)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── SECTION 3: Metal Type Tabs ──
  Widget _buildMetalTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0xFF5E5E5E)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: ['Gold', 'Silver', 'Diamond', 'Jewellery'].map((item) {
            final type = item.toLowerCase();
            final isActive = type == _metalType;
            final isLocked = type == 'jewellery';
            return Expanded(
              child: GestureDetector(
                onTap: isLocked ? null : () => setState(() => _metalType = type),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? (type == 'gold'
                            ? const LinearGradient(colors: [Color(0xFFFED55C), Color(0xFFDA9500)])
                            : type == 'diamond'
                                ? const LinearGradient(colors: [Color(0xFF0073CE), Color(0xFF003A68)])
                                : const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFF999999)]))
                        : null,
                    color: isActive ? null : Colors.black,
                    borderRadius: BorderRadius.circular(isActive ? 30 : 20),
                  ),
                  alignment: Alignment.center,
                  child: isLocked
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(item, style: const TextStyle(fontSize: 15, color: Color(0xFF7E7E7E), fontFamily: 'Lato')),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accentColor.withOpacity(0.6)), color: const Color(0xFF0D0902)),
                              child: Icon(Icons.lock, size: 13, color: _accentColor),
                            ),
                          ],
                        )
                      : Text(item, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isActive ? Colors.black : const Color(0xFF7E7E7E), fontFamily: 'Lato')),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── SECTION 4: Quick Actions ──
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: _isDiamond
          ? Row(
              children: [
                _buildQuickActionItem(label: 'Buy Diamond', icon: Icons.diamond, bg: const Color(0xFF044BA6), fg: Colors.white, onTap: () => context.go(AppRoutes.buyDiamonds)),
                const SizedBox(width: 8),
                _buildQuickActionItem(label: 'Cart', icon: Icons.shopping_cart, bg: const Color(0xFF233737), fg: const Color(0xFF6DD6FF), onTap: () => context.go(AppRoutes.cart)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionCircle(
                  label: 'Buy ${_isGold ? "Gold" : "Silver"}',
                  icon: Icons.shopping_cart,
                  bg: _iconBg,
                  fg: _accentColor,
                  onTap: () => context.go(_isDiamond ? AppRoutes.buyDiamonds : '/buy-gold/select?metal=$_metalType'),
                ),
                _buildQuickActionCircle(
                  label: 'Sell / Redemption',
                  icon: Icons.account_balance_wallet,
                  bg: const Color(0xFF233737),
                  fg: const Color(0xFF6DD6FF),
                  onTap: () => context.go('/sell-gold/select?metal=$_metalType'),
                ),
                _buildQuickActionCircle(
                  label: 'SIP',
                  icon: Icons.swap_horiz,
                  bg: const Color(0xFF233737),
                  fg: const Color(0xFF6DD6FF),
                  onTap: () => _showComingSoon('SIP'),
                ),
                _buildQuickActionCircle(
                  label: 'History',
                  icon: Icons.history,
                  bg: const Color(0xFF233737),
                  fg: const Color(0xFF6DD6FF),
                  onTap: () => context.go(AppRoutes.orders),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActionCircle({required String label, required IconData icon, required Color bg, required Color fg, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 24, color: fg)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8C8B8B), fontFamily: 'Lato'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({required String label, required IconData icon, required Color bg, required Color fg, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24, color: fg), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, color: fg, fontFamily: 'Lato'))]),
        ),
      ),
    );
  }

  // ── SECTION 5: Gold Certificate Button + Audit Report ──
  Widget _buildGoldCertificateSection() {
    return Column(
      children: [
        // Gold Certificate Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.goldCertificate),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFFFDD45B), Color(0xFFDE9C0A)])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/splash_logo.png', height: 16, width: 16),
                  const SizedBox(width: 8),
                  const Text('Download Gold Certificate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
                ],
              ),
            ),
          ),
        ),
        // Audit Report Card
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.auditCertificate),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF21211A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A20)),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AUDIT CONDUCTED ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF7CD57))),
                      const SizedBox(height: 4),
                      const Text('29/06/2026', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      Container(height: 1, color: const Color(0xFF2A2A20)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF15EE01))),
                          const SizedBox(width: 6),
                          const Text('Status: Successful', style: TextStyle(fontSize: 12, color: Color(0xFF9E9A94))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(colors: [Color(0xFFFDD45B), Color(0xFFDE9C0A)]),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf, size: 14, color: Colors.black),
                            SizedBox(width: 6),
                            Text('View Audit Report (PDF)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // File icon top-right
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFFF7CD57), size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── SECTION 6: Asset Overview ──
  Widget _buildAssetOverview(RateState rateState, HomeState homeState) {
    final investment = homeState.investment;
    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;

    final goldValue = investment.goldHoldingWithMultiplier * goldRate;
    final silverValue = investment.silverHoldingWithMultiplier * silverRate;
    final portfolioValue = goldValue + silverValue;
    final profit = portfolioValue - (investment.goldTotalInvested + investment.silverTotalInvested);

    final assets = _isDiamond
        ? [
            _AssetData(label: 'Diamond Holdings', value: '0.00ct', icon: Icons.diamond, btnLabel: 'Buy Diamond', btnAction: () => context.go(AppRoutes.buyDiamonds)),
            _AssetData(label: "Today's Live Rate", value: 'Rs.0/g', icon: Icons.trending_up, btnLabel: 'Invest More', btnAction: () => context.go(AppRoutes.buyDiamonds)),
            _AssetData(label: 'Total Profit', value: _formatCurrency(profit), icon: Icons.account_balance),
          ]
        : _isSilver
            ? [
                _AssetData(label: 'Silver Holdings', value: _formatGrams(investment.silverHoldingWithMultiplier), icon: Icons.monetization_on, btnLabel: 'Buy Silver', btnAction: () => context.go('/buy-gold/select?metal=silver')),
                _AssetData(label: "Today's Rate", value: 'Rs.${silverRate.toStringAsFixed(2)}/g', icon: Icons.trending_up, btnLabel: 'Invest More', btnAction: () => context.go('/buy-gold/select?metal=silver')),
                _AssetData(label: 'Total Profit', value: _formatCurrency(profit), icon: Icons.account_balance),
              ]
            : [
                _AssetData(label: 'Gold Holdings', value: _formatGrams(investment.goldHoldingWithMultiplier), icon: Icons.monetization_on, btnLabel: 'Buy Gold', btnAction: () => context.go('/buy-gold/select?metal=gold')),
                _AssetData(label: "Today's Rate", value: 'Rs.${goldRate.toStringAsFixed(2)}/g', icon: Icons.trending_up, btnLabel: 'Invest More', btnAction: () => context.go('/buy-gold/select?metal=gold')),
                _AssetData(label: 'Total Profit', value: _formatCurrency(profit), icon: Icons.account_balance),
              ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Asset Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato')),
              Text('All >', style: TextStyle(fontSize: 12, color: const Color(0xFF8C8B8B), fontFamily: 'Lato')),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: assets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildAssetCard(assets[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(_AssetData asset) {
    return Container(
      width: 163,
      decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Container(width: 30, height: 30, decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle), child: Icon(asset.icon, size: 14, color: _accentColor)),
                const SizedBox(width: 6),
                Expanded(child: Text(asset.label, style: const TextStyle(fontSize: 10, color: Color(0xFFBCBCBC), fontFamily: 'Lato'), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(asset.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato'))),
          const Spacer(),
          if (asset.btnLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: GestureDetector(
                onTap: asset.btnAction,
                child: Container(
                  width: double.infinity,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _isDiamond ? [const Color(0xFF0073CE), const Color(0xFF003A68)] : _isSilver ? [Colors.white, const Color(0xFF999999)] : [const Color(0xFFF9C748), const Color(0xFFD38312)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(asset.btnLabel!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isSilver || _isDiamond ? Colors.white : Colors.black, fontFamily: 'Lato'))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── SECTION 7: Buy Now Button ──
  Widget _buildBuyNowButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: GestureDetector(
        onTap: () {
          if (_isDiamond) {
            context.go(AppRoutes.buyDiamonds);
          } else {
            context.go('/buy-gold/select?metal=$_metalType');
          }
        },
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: _isDiamond
                  ? [const Color(0xFF044BA6), const Color(0xFF021D40)]
                  : _isSilver
                      ? [Colors.white, const Color(0xFF999999)]
                      : [const Color(0xFFFED45C), const Color(0xFFDB9502)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BUY ${_isDiamond ? "DIAMOND" : _isSilver ? "SILVER" : "GOLD"} NOW',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isSilver || _isDiamond ? Colors.white : Colors.black, fontFamily: 'Lato'),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: Icon(Icons.arrow_forward, size: 14, color: _isSilver || _isDiamond ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION 8: AI Insight ──
  Widget _buildAIInsight() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: const Alignment(-0.65, 0.18),
            end: const Alignment(0.65, -0.88),
            colors: [
              const Color(0xFF12100B),
              _isGold ? const Color(0xFF1A1710) : _isSilver ? const Color(0xFF283340) : const Color(0xFF0A1520),
              _isDiamond ? const Color(0xFF063E7F) : const Color(0xFF1A1710),
            ],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: const Alignment(-0.38, 0.22),
                  end: const Alignment(0.74, 0.74),
                  colors: _isGold ? [const Color(0xFFFBCE49), const Color(0xFFD79200)] : [const Color(0xFF838DA2), Colors.white],
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 24, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI INSIGHT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accentColor, fontFamily: 'Lato')),
                  const SizedBox(height: 4),
                  Text(
                    _isDiamond ? 'Diamond prices expected to rise' : _isSilver ? 'Silver prices expected to rise' : 'Gold prices expected to rise',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isDiamond ? '1.2% this week' : _isSilver ? '1.6% this week' : '2.4% this week',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accentColor, fontFamily: 'Lato'),
                  ),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: const Alignment(-0.38, 0.22),
                  end: const Alignment(0.74, 0.74),
                  colors: _isGold ? [const Color(0xFFFBCE49), const Color(0xFFD79200)] : [const Color(0xFF838DA2), Colors.white],
                ),
              ),
              child: const Icon(Icons.android, size: 36, color: Colors.black),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // ── SECTION 9: Recent Transactions ──
  Widget _buildRecentTransactions(OrdersState ordersState) {
    final recentOrders = ordersState.orders.take(10).toList();
    final recentDiamondOrders = ordersState.diamondOrders.take(10).toList();

    final filteredAugmont = _isDiamond
        ? <AugmontOrder>[]
        : (_orderFilter == 'all'
            ? recentOrders
            : recentOrders.where((o) => o.type.toUpperCase() == _orderFilter.toUpperCase()).toList());
    final filteredDiamond = _isDiamond
        ? (_orderFilter == 'all' || _orderFilter == 'buy' ? recentDiamondOrders : <DiamondOrder>[])
        : <DiamondOrder>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato')),
              GestureDetector(onTap: () => context.go(AppRoutes.orders), child: Text('All >', style: TextStyle(fontSize: 12, color: const Color(0xFF8C8B8B), fontFamily: 'Lato'))),
            ],
          ),
        ),
        // Filter pills
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Container(
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4E4E4E), width: 1),
              color: const Color(0xFF24201A),
            ),
            child: Row(
              children: ['all', 'buy', 'sell', 'redeem'].map((f) {
                final isActive = _orderFilter == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _orderFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: isActive ? LinearGradient(colors: _isDiamond ? [const Color(0xFF0073CE), const Color(0xFF003A68)] : _isSilver ? [Colors.white, const Color(0xFF999999)] : [const Color(0xFFFED75D), const Color(0xFFECB000), const Color(0xFFD48D00)]) : null,
                        color: isActive ? null : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? (_isSilver || _isDiamond ? Colors.white : Colors.black) : const Color(0xFF8C8B8B)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (ordersState.loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: Color(0xFFF7CD57), strokeWidth: 2)))
        else if (_isDiamond ? filteredDiamond.isEmpty : filteredAugmont.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No transactions found', style: TextStyle(color: const Color(0xFF8C8B8B), fontSize: 12))),
          )
        else
          ...(_isDiamond
              ? filteredDiamond.map((order) => _buildDiamondTransactionCardV2(order))
              : filteredAugmont.map((order) => _buildTransactionCardV2(order))),
      ],
    );
  }

  Widget _buildTransactionCard(AugmontOrder order) {
    final isBuy = order.type.toUpperCase() == 'BUY';
    final isSell = order.type.toUpperCase() == 'SELL';
    final metalName = order.metalType.toLowerCase() == 'silver' ? 'Silver' : 'Gold';
    final displayName = isBuy ? 'Digital $metalName' : metalName;
    final badgeLabel = isBuy ? 'Invested' : order.type.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor, width: 0.5)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSell ? const Color(0xFF213435) : _iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSell ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: isSell ? const Color(0xFF6DD6FF) : _accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: isSell ? const Color(0xFF243736) : _badgeBg, borderRadius: BorderRadius.circular(3)),
                        child: Text(badgeLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: isSell ? const Color(0xFF6DD6FF) : _accentColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.gold > 0 ? "${order.gold.toStringAsFixed(2)}g · " : ""}Rs.${order.rate.toInt()}/g · ${_formatDate(order.date)}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF6E6E6E), fontFamily: 'Lato'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCurrency(order.amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                const SizedBox(height: 2),
                Text(
                  order.status,
                  style: TextStyle(fontSize: 8, color: order.status.toLowerCase() == 'pending' ? const Color(0xFFFFCD0F) : const Color(0xFF15EE01)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCardV2(AugmontOrder order) {
    final isBuy = order.type.toUpperCase() == 'BUY';
    final isSell = order.type.toUpperCase() == 'SELL';
    final isDiamond = order.metalType.toLowerCase() == 'diamond';
    final metalName = order.metalType.toLowerCase() == 'silver' ? 'Silver' : 'Gold';
    final displayName = isBuy ? (isDiamond ? 'Diamond' : 'Digital $metalName') : (isDiamond ? 'Diamond' : metalName);
    final badgeLabel = isBuy ? 'Invested' : order.type.toUpperCase();
    final reference = order.merchantTransactionId.isNotEmpty ? order.merchantTransactionId : order.transactionId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor, width: 0.5)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSell ? const Color(0xFF213435) : _iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSell ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: isSell ? const Color(0xFF6DD6FF) : _accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: isSell ? const Color(0xFF243736) : _badgeBg, borderRadius: BorderRadius.circular(3)),
                        child: Text(badgeLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: isSell ? const Color(0xFF6DD6FF) : _accentColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reference.isNotEmpty ? "$reference - " : ""}'
                    '${order.gold > 0 ? "${order.gold.toStringAsFixed(2)}g" : ""}'
                    '${order.gold > 0 && order.rate > 0 ? " - " : ""}'
                    '${order.rate > 0 ? "Rs.${order.rate.toStringAsFixed(0)}/g" : ""}'
                    '${order.rate > 0 || order.gold > 0 ? " - " : ""}'
                    '${_formatDate(order.date)}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF6E6E6E), fontFamily: 'Lato'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCurrency(order.amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                const SizedBox(height: 2),
                Text(
                  order.status,
                  style: TextStyle(fontSize: 8, color: order.status.toLowerCase() == 'pending' ? const Color(0xFFFFCD0F) : const Color(0xFF15EE01)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamondTransactionCardV2(DiamondOrder order) {
    final reference = order.orderReference.isNotEmpty ? order.orderReference : order.orderId;
    final status = order.paymentStatus.isNotEmpty ? order.paymentStatus : (order.orderStatus.isNotEmpty ? order.orderStatus : 'Pending');
    final isPending = status.toLowerCase() == 'pending';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor, width: 0.5)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFF0A2A3B), shape: BoxShape.circle),
              child: const Icon(Icons.diamond_outlined, size: 18, color: Color(0xFF3AC7FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Diamond', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFF0A2A3B), borderRadius: BorderRadius.circular(3)),
                        child: const Text('Invested', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF3AC7FF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reference.isNotEmpty ? "$reference - " : ""}'
                    '${order.totalAmount > 0 ? "Rs.${order.totalAmount.toStringAsFixed(2)}" : ""}'
                    '${order.totalAmount > 0 ? " - " : ""}'
                    '${_formatDate(order.createdAt)}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF6E6E6E), fontFamily: 'Lato'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCurrency(order.totalAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Lato')),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(fontSize: 8, color: isPending ? const Color(0xFFFFCD0F) : const Color(0xFF15EE01)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION 10: Powered By ──
  Widget _buildPoweredBy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor.withOpacity(0.12)),
          color: _panelColor,
        ),
        child: Column(
          children: [
            Text('Powered by Augmont', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accentColor, fontFamily: 'Lato')),
            const SizedBox(height: 4),
            const Text(
              "Backed by India's leading digital gold infrastructure",
              style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E), fontFamily: 'Lato'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Coming Soon Modal ──
  void _showComingSoon(String feature) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF242320), Color(0xFF1A1918)]),
          border: Border.all(color: _borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _iconBg),
              child: Icon(_isGold ? Icons.auto_awesome : Icons.diamond, size: 30, color: _accentColor),
            ),
            const SizedBox(height: 16),
            Text('$feature Coming Soon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('This feature is under development.', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E)), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: _isDiamond ? [const Color(0xFF0073CE), const Color(0xFF003A68)] : [const Color(0xFFFED75D), const Color(0xFFD48D00)])),
                child: Center(child: Text('Notify Me', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isSilver || _isDiamond ? Colors.white : Colors.black))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetData {
  final String label;
  final String value;
  final IconData icon;
  final String? btnLabel;
  final VoidCallback? btnAction;

  const _AssetData({required this.label, required this.value, required this.icon, this.btnLabel, this.btnAction});
}
