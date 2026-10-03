import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/home_provider.dart';
import '../../core/storage/local_storage.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _loading = true;
  _OrderData? _lastOrder;
  String _kycStatus = 'Not Started';
  double _goldBuy = 0;
  double _goldSell = 0;
  double _silverBuy = 0;
  double _silverSell = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final augmontUserRaw = LocalStorageService.getAugmontUser();
    String uniqueId = '';
    if (augmontUserRaw != null && augmontUserRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(augmontUserRaw);
        uniqueId = parsed['uniqueId']?.toString() ?? '';
      } catch (_) {}
    }

    final api = ref.read(augmontApiProvider);

    final results = await Future.wait<Map<String, dynamic>>([
      api.fetchLiveGoldRateSnapshot(),
      api.fetchAugmontBuyOrders(uniqueId: uniqueId),
      api.fetchAugmontRedeemOrders(uniqueId: uniqueId),
      uniqueId.isNotEmpty ? api.fetchProductOrders(uniqueId) : Future.value({'ok': false, 'orders': <dynamic>[]}),
    ]);

    if (!mounted) return;

    // Live rates
    final rateRes = results[0];
    if (rateRes['ok'] == true && rateRes['snapshot'] != null) {
      final snapshot = rateRes['snapshot'];
      _goldBuy = snapshot.gold.buyPrice;
      _goldSell = snapshot.gold.sellPrice;
      _silverBuy = snapshot.silver.buyPrice;
      _silverSell = snapshot.silver.sellPrice;
    }

    final allOrders = <_OrderData>[];
    for (int i = 1; i < results.length; i++) {
      final result = results[i];
      if (result['ok'] == true) {
        final orders = result['orders'];
        if (orders is List) {
          for (final o in orders) {
            String type = 'BUY';
            double amount = 0;
            double gold = 0;
            double rate = 0;
            String date = '';
            String metalType = 'gold';
            if (o is Map<String, dynamic>) {
              type = (o['type']?.toString() ?? 'BUY').toUpperCase();
              amount = double.tryParse(o['amount']?.toString() ?? '0') ?? 0;
              gold = double.tryParse(o['gold']?.toString() ?? '0') ?? 0;
              rate = double.tryParse(o['rate']?.toString() ?? '0') ?? 0;
              date = o['date']?.toString() ?? '';
              metalType = o['metalType']?.toString() ?? 'gold';
            }
            allOrders.add(_OrderData(type: type, amount: amount, gold: gold, rate: rate, date: date, metalType: metalType));
          }
        }
      }
    }

    allOrders.sort((a, b) => b.date.compareTo(a.date));
    if (allOrders.isNotEmpty) {
      _lastOrder = allOrders.first;
    }

    final authState = ref.read(authProvider);
    _kycStatus = authState.user?.kycStatus ?? 'Not Started';

    if (mounted) setState(() => _loading = false);
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildLiveRatesCard(_goldBuy, _goldSell, _silverBuy, _silverSell, _loading),
                  const SizedBox(height: 24),
                  _buildSectionHeader('EXPLORE MORE'),
                  const SizedBox(height: 12),
                  _buildDiamondsButton(),
                  const SizedBox(height: 10),
                  _buildComingSoonSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('RECENT ACTIVITY'),
                  const SizedBox(height: 12),
                  _buildRecentActivity(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 16),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0C9100)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF032101),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF15EE01),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '3 New',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15EE01)),
                    ),
                  ],
                ),
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
              children: [
                const Center(
                  child: Icon(Icons.notifications_outlined, color: Color(0xFFC1C1C1), size: 14),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEE0105),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRatesCard(double goldBuy, double goldSell, double silverBuy, double silverSell, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.2)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2A28), Color(0xFF0D1117)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF7CD57).withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE784), Color(0xFFC88912)],
                    ),
                  ),
                  child: const Icon(Icons.trending_up, color: Color(0xFF11130F), size: 16),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Live Rates',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF15EE01).withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1A301E),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF15EE01),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15EE01), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rate cards grid
            Row(
              children: [
                Expanded(child: _buildRateCard('Gold', goldBuy, goldSell, const Color(0xFFF7CD57), isLoading)),
                const SizedBox(width: 12),
                Expanded(child: _buildRateCard('Silver', silverBuy, silverSell, const Color(0xFFE2E8F0), isLoading)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(String label, double buy, double sell, Color accent, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        color: Colors.black.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Buy', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF8D8B87))),
              Text(
                isLoading ? '...' : (buy > 0 ? '₹${buy.round().toStringAsFixed(0)}' : '---'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sell', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF8D8B87))),
              Text(
                isLoading ? '...' : (sell > 0 ? '₹${sell.round().toStringAsFixed(0)}' : '---'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE784), Color(0xFFC88912)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBFBFBF),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          ref.read(activeMetalProvider.notifier).state = 'diamond';
          context.go(AppRoutes.home);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF0A3A6B), Color(0xFF061E45)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5AC8FF).withOpacity(0.09),
                  border: Border.all(color: const Color(0xFF5AC8FF).withOpacity(0.21)),
                ),
                child: const Icon(Icons.diamond_outlined, color: Color(0xFF5AC8FF), size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diamonds',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFA0D8FF)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Certified natural diamonds',
                      style: TextStyle(fontSize: 10, color: Color(0xFF7AACC8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF5AC8FF), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonSection() {
    const items = [
      _ComingSoonItem(
        icon: Icons.diamond_outlined,
        label: 'Diamonds',
        desc: 'Certified natural diamonds',
        startColor: Color(0xFF0A3A6B),
        endColor: Color(0xFF061E45),
        iconColor: Color(0xFF5AC8FF),
        labelColor: Color(0xFFA0D8FF),
        descColor: Color(0xFF7AACC8),
      ),
      _ComingSoonItem(
        icon: Icons.watch_outlined,
        label: 'Jewellery',
        desc: 'Gold & silver ornaments',
        startColor: Color(0xFF4A3A1E),
        endColor: Color(0xFF2A2010),
        iconColor: Color(0xFFFFD966),
        labelColor: Color(0xFFFFE599),
        descColor: Color(0xFFC4A94D),
      ),
      _ComingSoonItem(
        icon: Icons.repeat,
        label: 'SIP',
        desc: 'Automated monthly investing',
        startColor: Color(0xFF1A2E30),
        endColor: Color(0xFF0D1818),
        iconColor: Color(0xFF7AD4E8),
        labelColor: Color(0xFFA0E8F0),
        descColor: Color(0xFF5EAAB8),
      ),
      _ComingSoonItem(
        icon: Icons.card_giftcard,
        label: 'Rewards & Referrals',
        desc: 'Earn while you invest',
        startColor: Color(0xFF3D2E14),
        endColor: Color(0xFF1E1708),
        iconColor: Color(0xFFFFD966),
        labelColor: Color(0xFFFFE599),
        descColor: Color(0xFFC4A94D),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildComingSoonCard(item),
        )).toList(),
      ),
    );
  }

  Widget _buildComingSoonCard(_ComingSoonItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [item.startColor, item.endColor],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.iconColor.withOpacity(0.09),
              border: Border.all(color: item.iconColor.withOpacity(0.21)),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: item.labelColor),
                ),
                const SizedBox(height: 2),
                Text(
                  item.desc,
                  style: TextStyle(fontSize: 10, color: item.descColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              color: Colors.white.withOpacity(0.06),
            ),
            child: const Text(
              'Soon',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFA0A0A0), letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activityItems = <_ActivityItem>[];

    if (_lastOrder != null) {
      final isBuy = _lastOrder!.type == 'BUY';
      final metalLabel = _lastOrder!.metalType == 'diamond' ? 'Diamond' : (_lastOrder!.metalType == 'silver' ? 'Silver' : 'Gold');
      activityItems.add(_ActivityItem(
        icon: Icons.trending_up,
        iconBg: const Color(0xFFF7CD57),
        title: isBuy ? '$metalLabel Purchase Successful' : '$metalLabel Redeemed',
        subtitle: isBuy
            ? 'You purchased ${_lastOrder!.gold.toStringAsFixed(2)}g of ${metalLabel.toLowerCase()} at ₹${_lastOrder!.rate.round()}/g'
            : '${_lastOrder!.gold.toStringAsFixed(2)}g ${metalLabel.toLowerCase()} sold at ₹${_lastOrder!.rate.round()}/g',
        time: _formatTimeAgo(_lastOrder!.date),
      ));
    }

    IconData kycIcon;
    Color kycIconBg;
    String kycTitle;
    String kycSubtitle;
    if (_kycStatus == 'Verified') {
      kycIcon = Icons.check_circle;
      kycIconBg = const Color(0xFF15EE01);
      kycTitle = 'KYC Verified';
      kycSubtitle = 'Your identity is verified';
    } else if (_kycStatus == 'Pending') {
      kycIcon = Icons.warning_amber_rounded;
      kycIconBg = const Color(0xFFF7CD57);
      kycTitle = 'KYC Pending';
      kycSubtitle = 'Verification in progress';
    } else {
      kycIcon = Icons.cancel_outlined;
      kycIconBg = const Color(0xFFFF6B6B);
      kycTitle = 'KYC Not Started';
      kycSubtitle = 'Complete KYC to unlock features';
    }
    activityItems.add(_ActivityItem(
      icon: kycIcon,
      iconBg: kycIconBg,
      title: kycTitle,
      subtitle: kycSubtitle,
      time: '',
    ));

    if (activityItems.isEmpty && _loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E2E2E).withOpacity(0.6)),
            color: const Color(0xFF0F1416),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF202326)),
                child: const Icon(Icons.hourglass_empty, color: Color(0xFFBFBFBF), size: 18),
              ),
              const SizedBox(width: 14),
              const Text('Loading...', style: TextStyle(fontSize: 13, color: Color(0xFF7E7E7E))),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: activityItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildActivityItem(item),
        )).toList(),
      ),
    );
  }

  Widget _buildActivityItem(_ActivityItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E).withOpacity(0.6)),
        color: const Color(0xFF0F1416),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.iconBg.withOpacity(0.08),
            ),
            child: Icon(item.icon, color: item.iconBg, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
          ),
          if (item.time.isNotEmpty)
            Text(
              item.time,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF5E5E5E)),
            ),
        ],
      ),
    );
  }
}

class _OrderData {
  final String type;
  final double amount;
  final double gold;
  final double rate;
  final String date;
  final String metalType;

  const _OrderData({
    required this.type,
    required this.amount,
    required this.gold,
    required this.rate,
    required this.date,
    required this.metalType,
  });
}

class _ComingSoonItem {
  final IconData icon;
  final String label;
  final String desc;
  final Color startColor;
  final Color endColor;
  final Color iconColor;
  final Color labelColor;
  final Color descColor;

  const _ComingSoonItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.startColor,
    required this.endColor,
    required this.iconColor,
    required this.labelColor,
    required this.descColor,
  });
}

class _ActivityItem {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
