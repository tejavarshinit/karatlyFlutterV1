import 'dart:math';
import 'dart:ui';
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
import '../invoice/invoice_download_util.dart';
import '../shared/kyc_action_prompt_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _metalType = 'gold';
  String _orderFilter = 'all';
  bool _showAllTransactions = false;
  String _invoiceStatusKey = '';
  String _invoiceStatusMessage = '';
  bool _invoiceDownloading = false;

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
      final normalized = dateStr.replaceFirst(' ', 'T');
      final d = DateTime.parse(normalized);
      final now = DateTime.now();
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      final time = DateFormat('h:mm a').format(d);
      if (isToday) return 'Today - $time';
      final yesterday = now.subtract(const Duration(days: 1));
      if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Yesterday - $time';
      return '${DateFormat('MMM dd').format(d)} - $time';
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
                _buildMetalTabs(),
                _buildQuickActions(),
                _buildCtaSection(),
                _buildPortfolioStatementSection(),
                if (!_isDiamond) _buildAssetOverview(rateState, homeState),
                _buildAIInsight(),
                _buildRecentTransactions(ordersState),
                _buildPoweredBy(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SECTION 1: Header ──
  Widget _buildHeader(RateState rateState) {
    final authState = ref.watch(authProvider);
    final isKycVerified = authState.user?.kycApproved == true;
    final kr = rateState.currentRate;
    final rate = _isSilver ? (kr?.silver.buyPrice ?? 0) : (kr?.buyPrice ?? 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/KaratlyLOGO-removebg-preview.png', width: 36, height: 36, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Karatly', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Playfair Display')),
              Text(
                _isGold ? 'PREMIUM GOLD' : _isSilver ? 'PREMIUM SILVER' : 'PREMIUM DIAMOND',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2,
                  color: _isGold ? const Color(0xFFC9A84C) : _isSilver ? const Color(0xFFE2E8F0) : const Color(0xFF4593F9)),
              ),
            ],
          ),
          const Spacer(),
          if (!_isDiamond && kr != null)
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 28, padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isGold ? const Color(0x73E8B438) : const Color(0x61FFFFFF)),
                  gradient: _isGold
                      ? const LinearGradient(colors: [Color(0xFF3A2A04), Color(0xFF1A1408), Color(0xFF0D0902)])
                      : const LinearGradient(colors: [Color(0xFF3B4654), Color(0xFF171D24), Color(0xFF0D1117)]),
                  boxShadow: [BoxShadow(color: (_isGold ? const Color(0xFFF7CD57) : const Color(0xFFC6CDD7)).withValues(alpha: 0.1), blurRadius: 22)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, gradient: _isGold ? const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFD48D00)]) : const LinearGradient(colors: [Color(0xFFE5EAF0), Color(0xFF94A3B8)]))),
                  const SizedBox(width: 4),
                  Text(_isGold ? 'Gold' : 'Silver', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: _isGold ? const Color(0xFFF7CD57) : const Color(0xFFE5EAF0))),
                  const SizedBox(width: 2),
                  Text('Rs.${rate.toStringAsFixed(0)}/g', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                ]),
              ),
            ),
          const SizedBox(width: 4),
          // KYC pill
          GestureDetector(
            onTap: () => context.go(AppRoutes.kycVerification),
            child: Container(
              height: 24, padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isKycVerified ? const Color(0x5915EE01) : const Color(0x6BEF4444)),
                gradient: isKycVerified
                    ? const LinearGradient(colors: [Color(0x2915EE01), Color(0xFF102015), Color(0xFF060A07)])
                    : const LinearGradient(colors: [Color(0x2EEF4444), Color(0xFF21100F), Color(0xFF080404)]),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: isKycVerified ? const Color(0xFF1A301E) : const Color(0xFF351313)),
                  child: Icon(isKycVerified ? Icons.check_circle : Icons.shield, size: 10, color: isKycVerified ? const Color(0xFF15EE01) : const Color(0xFFFF4D4D))),
                const SizedBox(width: 3),
                Text('KYC', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isKycVerified ? const Color(0xFFD7FFD3) : const Color(0xFFFF8A8A))),
              ]),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.go(AppRoutes.notifications),
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _isGold ? const Color(0xFFE8B438) : const Color(0xFF7388A5)), color: _isGold ? const Color(0xFF1D170D) : const Color(0xFF1D2530)),
              child: Stack(alignment: Alignment.center, children: [
                const Icon(Icons.notifications_outlined, size: 12, color: Color(0xFFC1C1C1)),
                const Positioned(right: 2, top: 2, child: SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEE0105), shape: BoxShape.circle)))),
              ]),
            ),
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
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? authState.fullName ?? 'Investor';
    final isKycVerified = authState.user?.kycApproved == true;

    final portfolioValue = _isGold
        ? investment.goldHoldingWithMultiplier * goldRate
        : _isSilver
            ? investment.silverHoldingWithMultiplier * silverRate
            : investment.goldHoldingWithMultiplier * goldRate + investment.silverHoldingWithMultiplier * silverRate;

    final passbookGrams = _isSilver ? investment.passbookSilverGrms : investment.passbookGoldGrms;
    final holdingGrams = passbookGrams > 0 ? passbookGrams : (_isSilver ? investment.silverHoldingWithMultiplier : investment.goldHoldingWithMultiplier);
    final portfolioLabel = _isDiamond ? 'PORTFOLIO VALUE' : (_isSilver ? 'SILVER PORTFOLIO VALUE' : 'GOLD PORTFOLIO VALUE');
    final holdingLabel = _isDiamond ? 'Total Portfolio' : (_isSilver ? 'Silver Holdings' : 'Gold Holdings');

    final bgAsset = _isDiamond ? 'assets/images/DiamondPortfolio.png' : _isSilver ? 'assets/images/silverbar.png' : 'assets/images/goldbar.png';

    // KYC non-verified purchase limit
    final fyTotal = investment.goldBuyPostTax + investment.silverBuyPostTax;
    final availableLimit = (1000 - fyTotal).clamp(0, 1000);
    final showKyc = !isKycVerified && availableLimit > 0;

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
            // Background pattern
            Positioned.fill(child: Opacity(opacity: 0.18, child: Image.asset(bgAsset, fit: BoxFit.cover))),
            // Overlay
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.78, 0.18),
                  radius: 0.24,
                  colors: [
                    (_isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFF7388A5) : const Color(0xFF0058C2)).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            )),
            // Watermark text logo
            Positioned(right: 16, top: 16,
              child: Opacity(opacity: 0.6,
                child: Image.asset('assets/images/K_logo_text-removebg-preview.png', height: 18, fit: BoxFit.contain))),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, _isDiamond || showKyc ? 176 : 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome,', style: TextStyle(fontSize: 10, color: const Color(0xFFA1A1A1))),
                    Text(userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isGold ? const Color(0xFFFFDB77) : Colors.white)),
                    if (!_isDiamond) ...[
                      const SizedBox(height: 4),
                      Text(portfolioLabel, style: const TextStyle(fontSize: 10, letterSpacing: 1.4, color: Color(0xFFBCBCBC))),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.only(top: 3),
                            child: Text('Rs.', style: TextStyle(fontSize: 26, fontWeight: FontWeight.normal, color: _isGold ? const Color(0xFFFFDB77) : Colors.white))),
                          const SizedBox(width: 4),
                          Text(
                            rateState.loading ? '...' : _formatCurrency(portfolioValue),
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isGold ? const Color(0xFFFFDB77) : Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${_formatGrams(holdingGrams)} $holdingLabel',
                        style: TextStyle(fontSize: 10, color: _isGold ? const Color(0xFFFFDB77) : Colors.white, fontFamily: 'Poppins')),
                    ],
                  ],
                ),
              ),
            ),
            // KYC Prompt inside card
            if (showKyc)
              Positioned(
                bottom: 16, right: 16,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.kycVerification),
                  child: Container(
                    width: 160, padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isGold ? const Color(0x47E8B438) : _isSilver ? const Color(0x4DE2E8F0) : const Color(0x470073CE)),
                      gradient: _isGold
                          ? const RadialGradient(center: Alignment(0.6, 0.4), radius: 130, colors: [Color(0xFF2C200C), Color(0xFF0B0802)])
                          : _isSilver
                              ? const RadialGradient(center: Alignment(0.5, 0.5), radius: 130, colors: [Color(0xFF19212E), Color(0xFF060912)])
                              : const RadialGradient(center: Alignment(0.5, 0.5), radius: 130, colors: [Color(0xFF0E1F30), Color(0xFF03070D)]),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: _isGold ? const LinearGradient(colors: [Color(0xFFC88912), Color(0xFF7D5502)])
                              : _isSilver ? const LinearGradient(colors: [Color(0xFF666666), Color(0xFF333333)])
                              : const LinearGradient(colors: [Color(0xFF0058C2), Color(0xFF002D5A)])),
                          child: Center(child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF15120B)),
                            child: Icon(Icons.shield, size: 14, color: _isGold ? const Color(0xFFF7CD57) : _isSilver ? Colors.white : const Color(0xFF0084FF))))),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Non-KYC Purchase Limit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Rs.${availableLimit.toInt()} ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFFF2F5F8) : const Color(0xFF0084FF))),
                        ])),
                      ]),
                      const SizedBox(height: 4),
                      const Text('Complete KYC to unlock higher purchase limit.', style: TextStyle(fontSize: 8, color: Color(0xFFBDB5A5))),
                      const SizedBox(height: 6),
                      Container(
                        height: 24, padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: (_isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFFE2E8F0) : const Color(0xFF0084FF)).withValues(alpha: 0.42)),
                          gradient: _isGold ? const LinearGradient(colors: [Color(0xFF2A210D), Color(0xFF120D05)])
                              : _isSilver ? const LinearGradient(colors: [Color(0xFF1D2530), Color(0xFF0D1117)])
                              : const LinearGradient(colors: [Color(0xFF0E1F30), Color(0xFF03070D)]),
                          boxShadow: [BoxShadow(color: (_isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFFE2E8F0) : const Color(0xFF0084FF)).withValues(alpha: 0.15), blurRadius: 8)],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Complete KYC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFFF2F5F8) : const Color(0xFF0084FF))),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 11, color: _isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFFF2F5F8) : const Color(0xFF0084FF)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── SECTION 3: Metal Type Tabs ──
  Widget _buildMetalTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 38,
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
                  onTap: isLocked ? null : () => setState(() {
                    _metalType = type;
                    ref.read(activeMetalProvider.notifier).state = type;
                  }),
                  child: Opacity(
                    opacity: isLocked ? 0.45 : 1.0,
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(item, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? (_isDiamond ? Colors.white : Colors.black) : const Color(0xFF7E7E7E), fontFamily: 'Lato')),
                          if (isLocked)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF7CD57).withValues(alpha: 0.6)), color: const Color(0xFF0D0902)),
                                  child: Icon(Icons.lock, size: 12, color: const Color(0xFFF7CD57)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: _isDiamond
          ? Row(children: [
              _buildQuickActionItem(label: 'Buy Diamond', icon: 'diamond', bg: const LinearGradient(colors: [Color(0xFF044BA6), Color(0xFF021D40)]), onTap: () => handleOpenDiamondFlow()),
              const SizedBox(width: 8),
              _buildQuickActionItem(label: 'Cart', icon: 'cart', bg: const LinearGradient(colors: [Color(0xFF233737), Color(0xFF233737)]), onTap: () => handleOpenDiamondFlow(isCart: true)),
            ])
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBuyMetalIcon(onTap: () => context.go('/buy-gold/select?metal=$_metalType'), label: 'Buy ${_isGold ? "Gold" : "Silver"}'),
                _buildSellIcon(onTap: () => context.go('/sell-gold/select?metal=$_metalType'), label: 'Sell / Redeem'),
                _buildQuickActionCircle(label: 'SIP', icon: Icons.swap_horiz, bg: const Color(0xFF233737), fg: const Color(0xFF6DD6FF), onTap: () => _showComingSoon('SIP')),
                _buildQuickActionCircle(label: 'History', icon: Icons.history, bg: const Color(0xFF233737), fg: const Color(0xFF6DD6FF), onTap: () => context.go(AppRoutes.orders)),
                if (_isGold)
                  _buildQuickActionCircle(label: 'Gift360', icon: Icons.card_giftcard, bg: const Color(0xFF3D3214), fg: const Color(0xFFF7CD57), onTap: () => context.go(AppRoutes.gift360), badge: 'UAT'),
              ],
            ),
    );
  }

  Widget _buildBuyMetalIcon({required VoidCallback onTap, required String label}) {
    final asset = _isSilver ? 'assets/images/Silveybuy2.jpeg' : 'assets/images/Buy_Gold.png';
    final glowColor = _isGold ? const Color(0xFFF7CD57) : const Color(0xFFC0C0C0);
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        _AnimatedBuyIcon(asset: asset, glowColor: glowColor),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF8C8B8B), fontFamily: 'Lato'), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildSellIcon({required VoidCallback onTap, required String label}) {
    final asset = _isSilver ? 'assets/images/Sell_&_Redeem_silver.png' : 'assets/images/Sell_&_Redeem_Gold.png';
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(23),
          child: Image.asset(asset, width: 46, height: 46, fit: BoxFit.cover)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF8C8B8B), fontFamily: 'Lato'), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildQuickActionCircle({required String label, required IconData icon, required Color bg, required Color fg, VoidCallback? onTap, String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 22, color: fg)),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D2E00),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFF7CD57).withValues(alpha: 0.4)),
                    ),
                    child: Text(badge, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8C8B8B), fontFamily: 'Lato'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({required String label, required String icon, required LinearGradient bg, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(gradient: bg, borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon == 'diamond')
              Image.asset('assets/images/Buy_Diamond_1.png', width: 32, height: 32, fit: BoxFit.contain)
            else
              Icon(Icons.shopping_cart, size: 24, color: const Color(0xFF6DD6FF)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'Lato')),
          ]),
        ),
      ),
    );
  }

  // ── SECTION 6: Asset Overview ──
  Widget _buildAssetOverview(RateState rateState, HomeState homeState) {
    final investment = homeState.investment;
    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;
    final now = DateTime.now();
    final dateLabel = DateFormat('dd MMM').format(now);

    final goldGrams = investment.passbookGoldGrms > 0 ? investment.passbookGoldGrms : investment.goldHoldingWithMultiplier;
    final silverGrams = investment.passbookSilverGrms > 0 ? investment.passbookSilverGrms : investment.silverHoldingWithMultiplier;

    final assets = _isSilver
        ? [
            _AssetData(label: 'Silver Holdings', value: _formatGrams(silverGrams), isHolding: true, btnLabel: 'Buy Silver', btnAction: () => context.go('/buy-gold/select?metal=silver')),
            _AssetData(label: "Today's Silver Rate ($dateLabel)", value: 'Rs.${silverRate.toStringAsFixed(2)}/g', isHolding: false, btnLabel: 'Invest More', btnAction: () => context.go('/buy-gold/select?metal=silver')),
          ]
        : [
            _AssetData(label: 'Gold Holdings', value: _formatGrams(goldGrams), isHolding: true, btnLabel: 'Buy Gold', btnAction: () => context.go('/buy-gold/select?metal=gold')),
            _AssetData(label: "Today's Gold Rate ($dateLabel)", value: 'Rs.${goldRate.toStringAsFixed(2)}/g', isHolding: false, btnLabel: 'Invest More', btnAction: () => context.go('/buy-gold/select?metal=gold')),
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
                asset.isHolding ? _buildHoldingIcon() : Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFF233737), shape: BoxShape.circle), child: const Icon(Icons.trending_up, size: 14, color: Color(0xFF3AC7FF))),
                const SizedBox(width: 6),
                Expanded(child: Text(asset.label, style: const TextStyle(fontSize: 10, color: Color(0xFFBCBCBC), fontFamily: 'Lato'))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(asset.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato'))),
          const Spacer(),
          // Sparkline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(height: 24, child: CustomPaint(size: const Size(140, 24), painter: _SparklinePainter(lineColor: asset.isHolding ? const Color(0xFFF8CF59) : const Color(0xFF3AC7FF)))),
          ),
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

  Widget _buildHoldingIcon() {
    if (_isGold) {
      return Container(
        width: 30, height: 30,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF3D3214), Color(0xFF3D3214)])),
        child: const Center(child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57)))),
      );
    }
    return Container(
      width: 30, height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF606B7A), Color(0xFF363E4B)]),
      ),
      child: const Center(child: Text('S', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))),
    );
  }

  // ── Buy CTA Section ──
  Widget _buildCtaSection() {
    final isDiamond = _metalType == 'diamond';
    final isSilver = _metalType == 'silver';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDiamond ? const Color(0xFF565555) : isSilver ? const Color(0xFF4E4E4E) : const Color(0xFFB28A3B)),
          gradient: isDiamond
              ? const LinearGradient(begin: Alignment(0.84, -0.14), end: Alignment.bottomLeft, colors: [Color(0xFF022B5B), Color(0xFF0D1115)])
              : isSilver
                  ? const LinearGradient(begin: Alignment(0.84, -0.14), end: Alignment.bottomLeft, colors: [Color(0xFF314053), Color(0xFF0D1115)])
                  : null,
          color: _isGold ? const Color(0xFF1A1710) : null,
        ),
        child: _BuyCtaButton(
          metalType: _metalType,
          onTap: () {
            if (isSilver) {
              context.go('/buy-gold/select?metal=silver');
            } else if (isDiamond) {
              handleOpenDiamondFlow();
            } else {
              context.go('/buy-gold/select?metal=gold');
            }
          },
        ),
      ),
    );
  }

  // ── SECTION 7b: Portfolio Statement + Audit Card ──
  Widget _buildPortfolioStatementSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          if (_isGold) ...[
            _buildGoldCertificateEntry(),
            const SizedBox(height: 16),
            _buildAuditReportCard(),
          ],
          if (_isSilver) ...[
            _buildSilverCertificateEntry(),
          ],
          if (_isDiamond) ...[
            _buildDiamondCertificateEntry(),
          ],
        ],
      ),
    );
  }

  Widget _buildGoldCertificateEntry() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.goldCertificate),
      child: Container(
        width: double.infinity, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFFFDD45B), Color(0xFFDE9C0A)])),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.description, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          const Text('Gold Portfolio Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
        ]),
      ),
    );
  }

  Widget _buildSilverCertificateEntry() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.silverCertificate),
      child: Container(
        width: double.infinity, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)])),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.description, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          const Text('Silver Portfolio Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
        ]),
      ),
    );
  }

  Widget _buildDiamondCertificateEntry() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.diamondCertificate),
      child: Container(
        width: double.infinity, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFFC7D2FE), Color(0xFF818CF8)])),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.description, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          const Text('Diamond Purchase Certificate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
        ]),
      ),
    );
  }

  Widget _buildAuditReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21211A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A20), width: 0.5),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AUDIT CONDUCTED ON', style: TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'Lato')),
              const SizedBox(height: 8),
              const Text('29/06/2026', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato')),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 0.5, color: Color(0xFFC9C9C9)),
              ),
              Row(
                children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D8E01)),
                    ),
                    child: const Center(
                      child: Icon(Icons.circle, size: 9, color: Color(0xFF0D8E01)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Status: Successful', style: TextStyle(fontSize: 12, color: Color(0xFF0D8E01), fontFamily: 'Lato')),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go(AppRoutes.auditCertificate),
                child: Container(
                  width: double.infinity, height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(colors: [Color(0xFFF8C546), Color(0xFFD68816)]),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 14, color: Colors.black),
                      SizedBox(width: 8),
                      Text('View Audit Report (PDF)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Lato')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            right: 0, top: 0,
            child: Icon(Icons.description, size: 48, color: Color(0xFFC9C9C9)),
          ),
        ],
      ),
    );
  }

  // ── SECTION 8: AI Insight ──
  Widget _buildAIInsight() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        width: double.infinity,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: const Alignment(-0.65, 0.18),
            end: const Alignment(0.65, -0.88),
            colors: [
              const Color(0xFF12100B),
              _isGold ? const Color(0xFF3D3214) : _isSilver ? const Color(0xFF283340) : const Color(0xFF063E7F),
              _isGold ? const Color(0xFF3D3214) : _isSilver ? const Color(0xFF283340) : const Color(0xFF063E7F),
            ],
          ),
          border: Border.all(color: const Color(0xFF4E4E4E)),
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
              child: Icon(Icons.auto_awesome, size: 24, color: _isGold ? const Color(0xFF8B6914) : const Color(0xFF1A2530)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 20, padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: _isGold ? [const Color(0xFFFBCE49), const Color(0xFFD79200)] : [const Color(0xFF838DA2), Colors.white],
                          ),
                        ),
                        child: Center(
                          child: Text('AI INSIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _isGold ? const Color(0xFF8B6914) : const Color(0xFF1A2530))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Updated 2m ago', style: TextStyle(fontSize: 10, color: Color(0xFF8B8B8B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isDiamond ? 'Diamond prices expected to rise' : _isSilver ? 'Silver prices expected to rise' : 'Gold prices expected to rise',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(
                    _isDiamond ? '1.2% this week' : _isSilver ? '1.6% this week' : '2.4% this week',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // ── SECTION 9: Recent Transactions ──
  Widget _buildRecentTransactions(OrdersState ordersState) {
    // Filter by selected metal tab (client-side, matching React)
    final metalFiltered = _isDiamond
        ? <AugmontOrder>[]
        : ordersState.orders.where((o) => o.metalType.toLowerCase() == _metalType).toList();
    metalFiltered.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime(0);
      final dateB = DateTime.tryParse(b.date) ?? DateTime(0);
      return dateB.compareTo(dateA);
    });
    final recentDiamondOrders = ordersState.diamondOrders.toList();

    // Apply type filter BEFORE take(5) — matching React behavior
    final showFilters = _isDiamond ? ['all', 'buy'] : ['all', 'buy', 'sell', 'redeem'];
    final typeFiltered = _isDiamond
        ? <AugmontOrder>[]
        : (_orderFilter == 'all'
            ? metalFiltered
            : metalFiltered.where((o) => o.type.toUpperCase() == _orderFilter.toUpperCase()).toList());
    final displayLimit = _showAllTransactions ? null : 5;
    final recentOrders = typeFiltered.take(displayLimit ?? typeFiltered.length).toList();
    final filteredDiamond = _isDiamond
        ? (_orderFilter == 'all' || _orderFilter == 'buy'
            ? recentDiamondOrders.take(displayLimit ?? recentDiamondOrders.length).toList()
            : <DiamondOrder>[])
        : <DiamondOrder>[];
    final filteredAugmont = _isDiamond ? <AugmontOrder>[] : recentOrders;
    final hasMore = _isDiamond
        ? recentDiamondOrders.length > 5
        : typeFiltered.length > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lato')),
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
              children: showFilters.map((f) {
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
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showAllTransactions = !_showAllTransactions),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _isDiamond
                          ? const LinearGradient(colors: [Color(0xFF0073CE), Color(0xFF003A68)])
                          : _isSilver
                              ? const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFF999999)])
                              : const LinearGradient(colors: [Color(0xFFFED55C), Color(0xFFDA9500)]),
                    ),
                    child: Text(
                      _showAllTransactions ? 'Show less' : 'Show more',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: _isDiamond ? Colors.white : (_isSilver ? Colors.black : Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
    );
  }

  Widget _buildTransactionCardV2(AugmontOrder order) {
    final isBuy = order.type.toUpperCase() == 'BUY';
    final isSell = order.type.toUpperCase() == 'SELL';
    final isRedeem = order.type.toUpperCase() == 'REDEEM';
    final mt = order.metalType.toLowerCase();
    final metalName = mt == 'silver' ? 'Silver' : mt == 'diamond' ? 'Diamond' : 'Gold';
    final displayName = isBuy ? (mt == 'diamond' ? 'Diamond' : 'Digital $metalName') : metalName;
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
                color: isSell || isRedeem ? const Color(0xFF213435) : _iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRedeem ? Icons.inventory_2_outlined : (isSell ? Icons.arrow_upward : Icons.arrow_downward),
                size: 18,
                color: isSell || isRedeem ? const Color(0xFF6DD6FF) : _accentColor,
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
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _badgeBg,
                    ),
                    child: Text(
                      'Applicable GST is reflected in the invoice.',
                      style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w600, color: _accentColor.withValues(alpha: 0.8)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _downloadInvoice(order),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, size: 11, color: _accentColor),
                          const SizedBox(width: 3),
                          Text(
                            'Invoice',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: _accentColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_invoiceStatusKey == (order.transactionId.isNotEmpty ? order.transactionId : order.merchantTransactionId) && _invoiceStatusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _invoiceStatusMessage,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: _invoiceDownloading
                              ? _accentColor
                              : (_invoiceStatusMessage.toLowerCase().contains('failed')
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF15EE01)),
                        ),
                      ),
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

  Future<void> _downloadInvoice(AugmontOrder order) async {
    if (!mounted) return;
    final type = order.type.toLowerCase();
    final invType = type == 'sell' ? 'sell' : (type == 'redeem' ? 'redeem' : 'buy');
    final key = order.transactionId.isNotEmpty ? order.transactionId : order.merchantTransactionId;
    setState(() {
      _invoiceStatusKey = key;
      _invoiceStatusMessage = 'Preparing invoice...';
      _invoiceDownloading = true;
    });
    final ok = await downloadInvoice(
      context: context,
      transactionId: key,
      type: invType,
      showSnackBar: false,
    );
    if (!mounted) return;
    setState(() {
      _invoiceStatusKey = key;
      _invoiceDownloading = false;
      _invoiceStatusMessage = ok ? 'Invoice downloaded' : 'Invoice download failed';
    });
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

  // ── SECTION 10: Powered By Augmont ──
  Widget _buildPoweredBy() {
    final borderColor = _isDiamond ? const Color(0x400073CE) : _isSilver ? const Color(0x40E2E8F0) : const Color(0x40E8B438);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          gradient: _isDiamond
              ? const LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF061020), Color(0xFF030810)])
              : _isSilver
                  ? const LinearGradient(colors: [Color(0xFF1A2030), Color(0xFF111820), Color(0xFF0A0E14)])
                  : const LinearGradient(colors: [Color(0xFF2A1E06), Color(0xFF1A1208), Color(0xFF0D0902)]),
        ),
        child: Column(
          children: [
            Text('Powered by Augmont, Powered by SafeGold',
              style: TextStyle(fontFamily: 'Alegreya', fontWeight: FontWeight.w500, fontSize: 22, color: Colors.white, height: 1.36)),
            const SizedBox(height: 8),
            Text("Backed by India's leading digital gold infrastructure and trusted banking partners",
              style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, fontSize: 11, color: const Color(0xFFC9C9C9), height: 1.27),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildPartnerLogo('assets/images/augmont.jpeg', 'Augmont', borderColor),
              const SizedBox(width: 20),
              _buildPartnerLogo('assets/images/safegold.jpeg', 'SafeGold', borderColor),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerLogo(String asset, String label, Color borderColor) {
    return Column(children: [
      Container(width: 120, height: 60,
        decoration: BoxDecoration(
          gradient: _isGold ? const LinearGradient(colors: [Color(0xFF1A1710), Color(0xFF0D0902)])
              : _isSilver ? const LinearGradient(colors: [Color(0xFF111820), Color(0xFF0A0E14)])
              : const LinearGradient(colors: [Color(0xFF061020), Color(0xFF030810)]),
          borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4E4E4E))),
        child: Padding(padding: const EdgeInsets.all(8), child: Image.asset(asset, fit: BoxFit.contain))),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: _isDiamond ? const Color(0xFF4593F9) : _isSilver ? const Color(0xFFE2E8F0) : const Color(0xFFF7CD57))),
    ]);
  }

  // ── SECTION 11: Footer ──
  Widget _buildFooter() {
    final borderColor = _isGold ? const Color(0x20E8B438) : _isSilver ? const Color(0xFF334155) : const Color(0xFF1E3A5F);
    final dividerColor = _isGold ? const Color(0xFF2A2010) : _isSilver ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F);
    final accentColor = _isGold ? const Color(0xFFF7CD57) : _isSilver ? const Color(0xFFE2E8F0) : const Color(0xFF4593F9);
    final accentColor2 = _isGold ? const Color(0xFFE5AF35) : _isSilver ? const Color(0xFF94A3B8) : const Color(0xFF1D4ED8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          color: _isDiamond ? const Color(0xFF0A1628) : _isSilver ? const Color(0xFF0D1117) : const Color(0xFF111008),
        ),
        child: Column(
          children: [
            // Title
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _gradientText('Karatly', accentColor, accentColor2),
              const Text(' | ', style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
              const Text('Digital Gold & Silver', style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
            ]),
            const SizedBox(height: 12),
            // Policy links
            Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8,
              children: [
                _footerLink('Privacy Policy', AppRoutes.privacyPolicy),
                _footerLink('Refund Policy', AppRoutes.refundPolicy),
                _footerLink('Terms', AppRoutes.terms),
                _footerLink('Terms of Use', AppRoutes.termsOfUse),
                _footerLink('Trademark Notice', AppRoutes.trademarkNotice),
                _footerLink('How It Works', AppRoutes.howItWorks),
                _footerLink('Why Karatly', AppRoutes.why),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),
            Text('${DateTime.now().year} Karatly. All rights reserved.', style: TextStyle(fontSize: 8, color: const Color(0xFF5E5E5E), height: 1.5)),
            const Text('Powered by Augmont \u2022 Backed by SafeGold', style: TextStyle(fontSize: 8, color: Color(0xFF5E5E5E), height: 1.5)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/image21.png', width: 32, height: 32, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Image.asset('assets/images/image22.png', width: 32, height: 32, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Image.asset('assets/images/image23.png', width: 32, height: 32, fit: BoxFit.contain),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(String label, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), decoration: TextDecoration.underline)),
    );
  }

  Widget _gradientText(String text, Color c1, Color c2) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(colors: [c1, c2]).createShader(bounds),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  // ── Diamond KYC Gatekeeper ──
  Future<void> handleOpenDiamondFlow({bool isCart = false}) async {
    final authState = ref.read(authProvider);
    final isKycVerified = authState.user?.kycApproved == true;

    if (!isKycVerified) {
      showKycActionPromptModal(
        context: context,
        onVerify: () async {
          await context.push('/kyc-verification');
          final updatedState = ref.read(authProvider);
          final nowVerified = updatedState.user?.kycApproved == true;
          if (nowVerified && isCart) {
            if (context.mounted) context.go(AppRoutes.cart);
          } else if (nowVerified) {
            if (context.mounted) context.go(AppRoutes.buyDiamonds);
          }
        },
      );
      return;
    }

    if (isCart) {
      context.go(AppRoutes.cart);
    } else {
      context.go(AppRoutes.buyDiamonds);
    }
  }

  // ── Coming Soon Modal ──
  void _showComingSoon(String feature) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Coming Soon',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: animation,
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Container(
              width: 350,
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
            ),  // Container
            ),  // DefaultTextStyle
          ),    // Material
        ),      // Center
      ),        // FadeTransition
    ),          // ScaleTransition
  );            // showGeneralDialog
  }
}

class _AssetData {
  final String label;
  final String value;
  final bool isHolding;
  final String? btnLabel;
  final VoidCallback? btnAction;

  const _AssetData({required this.label, required this.value, required this.isHolding, this.btnLabel, this.btnAction});
}

class _AnimatedBuyIcon extends StatefulWidget {
  final String asset;
  final Color glowColor;
  const _AnimatedBuyIcon({required this.asset, required this.glowColor});

  @override
  State<_AnimatedBuyIcon> createState() => _AnimatedBuyIconState();
}

class _AnimatedBuyIconState extends State<_AnimatedBuyIcon> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Glow opacity: [0,0,0,0.3,0.3,0] at times [0,0.08,0.08,0.24,0.24,1]
        final glowOpacity = _keyframe(t, [0, 0.08, 0.08, 0.24, 0.24, 1], [0.0, 0.0, 0.0, 0.3, 0.3, 0.0]);
        // Image opacity: [0.6,1,1,1,1,0.6] at times [0,0.16,0.2,0.24,1,1]
        final imgOpacity = _keyframe(t, [0, 0.16, 0.2, 0.24, 1, 1], [0.6, 1.0, 1.0, 1.0, 1.0, 0.6]);
        // Image scale: [0.95,1,1,1.06,1,0.95] at times [0,0.16,0.2,0.24,1,1]
        final imgScale = _keyframe(t, [0, 0.16, 0.2, 0.24, 1, 1], [0.95, 1.0, 1.0, 1.06, 1.0, 0.95]);
        // Image y offset: [0,0,3,3,0,0] at times [0,0.16,0.2,0.24,1,1]
        final imgY = _keyframe(t, [0, 0.16, 0.2, 0.24, 1, 1], [0.0, 0.0, 3.0, 3.0, 0.0, 0.0]);

        return SizedBox(
          width: 52, height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Glow layer
              Opacity(
                opacity: glowOpacity,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [widget.glowColor, widget.glowColor.withValues(alpha: 0.3), Colors.transparent],
                      radius: 0.7,
                    ),
                  ),
                ),
              ),
              // Animated icon image
              Transform.translate(
                offset: Offset(0, imgY),
                child: Transform.scale(
                  scale: imgScale,
                  child: Opacity(
                    opacity: imgOpacity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(widget.asset, width: 52, height: 52, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _keyframe(double t, List<double> times, List<double> values) {
    if (t <= times.first) return values.first;
    if (t >= times.last) return values.last;
    for (int i = 0; i < times.length - 1; i++) {
      if (t >= times[i] && t <= times[i + 1]) {
        final delta = (t - times[i]) / (times[i + 1] - times[i]);
        return values[i] + (values[i + 1] - values[i]) * delta;
      }
    }
    return values.last;
  }
}

// ── Buy CTA Button ──
class _BuyCtaButton extends StatefulWidget {
  final String metalType;
  final VoidCallback onTap;
  const _BuyCtaButton({required this.metalType, required this.onTap});
  @override
  _BuyCtaButtonState createState() => _BuyCtaButtonState();
}

class _BuyCtaButtonState extends State<_BuyCtaButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();
    _animation = Tween<double>(begin: -0.1, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.714, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDiamond = widget.metalType == 'diamond';
    final isSilver = widget.metalType == 'silver';
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.hardEdge,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isDiamond
                ? [const Color(0xFF044BA6), const Color(0xFF021D40)]
                : isSilver
                    ? [Colors.white, const Color(0xFF999999)]
                    : [const Color(0xFFFED45C), const Color(0xFFDB9502)]),
          ),
          child: Stack(children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  left: _animation.value * 350,
                  top: 0,
                  child: Transform.rotate(
                    angle: -0.21,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        width: 20,
                        height: 50,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            Colors.white60,
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isDiamond ? 'BUY DIAMOND NOW' : isSilver ? 'BUY SILVER NOW' : 'BUY GOLD NOW',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold,
                            color: isDiamond ? Colors.white : Colors.black,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Secure \u00B7 Fast \u00B7 Trusted',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDiamond ? Colors.white.withOpacity(0.8) : Colors.black,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: isDiamond ? 28 : 24,
                      height: isDiamond ? 28 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDiamond ? Colors.white.withOpacity(0.12) : Colors.black,
                      ),
                      child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color lineColor;
  _SparklinePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [0.2, 0.5, 0.3, 0.7, 0.4, 0.6, 0.5, 0.8, 0.6, 0.5, 0.7, 0.65, 0.8, 0.55, 0.85, 0.7, 0.9, 0.6, 0.95, 0.75];
    for (var i = 0; i < points.length; i += 2) {
      final x = points[i] * size.width;
      final y = size.height - (points[i + 1] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
