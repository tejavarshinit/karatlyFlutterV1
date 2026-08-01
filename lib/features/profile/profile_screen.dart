import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/home_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../features/certificate/download_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _AadhaarAddress {
  final String addressId;
  final String providerAddressId;
  final String name;
  final String addressLine;
  const _AadhaarAddress({
    required this.addressId,
    required this.providerAddressId,
    required this.name,
    required this.addressLine,
  });
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  _AadhaarAddress? _aadhaarAddress;
  double _goldGrams = 0;
  double _silverGrams = 0;
  DateTime? _statementFromDate;
  DateTime? _statementToDate;
  String? _downloadingStatement;
  String? _statementError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).fetchInvestmentData();
      _loadAadhaarAddressFromApi();
      _loadPassbookData();
    });
  }

  String _resolveUniqueId() {
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = profile['uniqueId']?.toString();
    if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    return '';
  }

  Future<void> _loadPassbookData() async {
    try {
      final uniqueId = _resolveUniqueId();
      if (uniqueId.isEmpty) return;
      final api = AugmontApi(ref.read(augmontDioProvider));
      final result = await api.fetchAugmontPassbook(uniqueId);
      if (result['ok'] == true && mounted) {
        final passbook = result['passbook'] as Map<String, dynamic>? ?? {};
        setState(() {
          _goldGrams = double.tryParse((passbook['goldGrms'] ?? passbook['goldBalance'] ?? passbook['balance'] ?? '0').toString()) ?? 0;
          _silverGrams = double.tryParse((passbook['silverGrms'] ?? passbook['silverBalance'] ?? '0').toString()) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAadhaarAddressFromApi() async {
    try {
      final uniqueId = ref.read(authProvider).user?.augmontUniqueId ?? LocalStorageService.getUserUniqueId();
      if (uniqueId == null || uniqueId.isEmpty) return;
      final api = AugmontApi(ref.read(augmontDioProvider));
      final response = await api.fetchAadhaarAddress(uniqueId: uniqueId);
      if (response['ok'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          final payload = data['payload'] as Map<String, dynamic>?;
          final result = payload?['result'] as Map<String, dynamic>?;
          final addressData = (result?['data'] as Map<String, dynamic>?) ??
              result ??
              payload ??
              data;
          final addressId = addressData?['addressId']?.toString() ?? '';
          final providerAddressId = addressData?['providerAddressId']?.toString() ?? '';
          final name = addressData?['name']?.toString() ?? '';
          final addressLine = addressData?['addressLine']?.toString() ?? addressData?['address']?.toString() ?? '';
          if (name.isNotEmpty && addressLine.isNotEmpty && mounted) {
            setState(() => _aadhaarAddress = _AadhaarAddress(
              addressId: addressId,
              providerAddressId: providerAddressId,
              name: name,
              addressLine: addressLine,
            ));
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final rateState = ref.watch(rateProvider);
    final investment = homeState.investment;
    final goldRate = rateState.currentRate?.buyPrice ?? 0;
    final silverRate = rateState.currentRate?.silver.buyPrice ?? 0;
    final portfolioValue = investment.goldHoldingWithMultiplier * goldRate
        + investment.silverHoldingWithMultiplier * silverRate;
    final name = authState.fullName ?? authState.user?.name ?? 'User';
    final phone = authState.phoneNumber ?? '';
    final email = authState.email ?? '';
    final isPanVerified = authState.user?.panVerified ?? false;
    final profileStatus = isPanVerified ? 'Verified' : _kycStatusLabel(authState.user?.kycStatus);

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9755, -0.3792),
          radius: 1.04,
          colors: [Color(0xFF4A3A1E), Colors.black],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, 'Profile'),
              const SizedBox(height: 22),
              Center(
                child: Column(
                  children: [
                    _buildAvatar(authState, name),
                    const SizedBox(height: 14),
                    _buildUserInfo(name: name, email: email),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildMetricsRow(
                goldGrams: _goldGrams,
                silverGrams: _silverGrams,
                portfolioValue: portfolioValue,
              ),
              const SizedBox(height: 24),
              _buildAadhaarSection(),
              SizedBox(height: _aadhaarAddress != null ? 22 : 24),
              _buildSectionHeading('ACCOUNT'),
              const SizedBox(height: 12),
              _buildKycRow(context, authState, profileStatus),
              _buildMenuRow(
                icon: Icons.account_balance_outlined,
                title: 'Add your bank',
                onTap: () => context.go(AppRoutes.paymentMethods),
              ),
              _buildLockedRewardsRow(),
              _buildTransactionStatement(),
              const SizedBox(height: 20),
              _buildSectionHeading('PREFERENCES'),
              const SizedBox(height: 12),
              _buildNotificationToggle(),
              _buildMenuRow(
                icon: Icons.shield_outlined,
                title: 'Security',
                onTap: () => context.go(AppRoutes.security),
              ),
              _buildMenuRow(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => context.go(AppRoutes.helpCenter),
              ),
              _buildMenuRow(
                icon: Icons.description_outlined,
                title: 'Terms & Condition',
                onTap: () => context.go(AppRoutes.terms),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Karatly v2.6.0 - Made with care',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),
              _buildSignOutButton(context, ref),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.go(AppRoutes.home),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
        ),
        Image.asset(
          'assets/images/KaratlyLOGO-removebg-preview.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1D170D),
            border: Border.all(color: const Color(0xFFE8B438)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.go(AppRoutes.notifications),
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(AuthState authState, String name) {
    final photoBase64 = authState.user?.profilePhoto;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8B438), width: 2),
        ),
        child: ClipOval(
          child: photoBase64 != null && photoBase64.isNotEmpty
              ? Builder(
                  builder: (_) {
                    try {
                      final base64Data = photoBase64.contains(',') ? photoBase64.split(',').last : photoBase64;
                      return Image.memory(
                        base64Decode(base64Data),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => _buildInitial(initial),
                      );
                    } catch (_) {
                      return _buildInitial(initial);
                    }
                  },
                )
              : _buildInitial(initial),
        ),
      ),
    );
  }

  Widget _buildInitial(String initial) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1A1A1A),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE8B438)),
        ),
      ),
    );
  }

  Widget _buildUserInfo({
    required String name,
    required String email,
  }) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
      ],
    );
  }

  Widget _buildMetricsRow({
    required double goldGrams,
    required double silverGrams,
    required double portfolioValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFFFFCD0F),
            label: 'Gold',
            value: '${goldGrams.toStringAsFixed(4)} g',
            accentColor: const Color(0xFFE8B438),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFFFFCD0F),
            label: 'Silver',
            value: '${silverGrams.toStringAsFixed(4)} g',
            accentColor: const Color(0xFF6DD6FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.shield,
            iconColor: const Color(0xFFFFCD0F),
            label: 'Portfolio',
            value: _formatCurrency(portfolioValue),
            accentColor: const Color(0xFF15EE01),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16181A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF7E7E7E))),
        ],
      ),
    );
  }

  Widget _buildAadhaarSection() {
    final addr = _aadhaarAddress;
    if (addr == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AADHAAR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 17 / 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1416),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF202326),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFE8B438)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addr.name.isNotEmpty ? addr.name : 'Aadhaar Address',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          addr.addressLine,
                          style: const TextStyle(fontSize: 11, height: 16 / 11, color: Color(0xFF7E7E7E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFBFBFBF),
        ),
      ),
    );
  }

  Widget _buildKycRow(BuildContext context, AuthState authState, String profileStatus) {
    final isVerified = profileStatus == 'Verified';
    final badgeBg = isVerified ? const Color(0xFF1A301E) : const Color(0xFF2D2513);
    final badgeColor = isVerified ? const Color(0xFF15EE01) : const Color(0xFFF7CD57);

    return _buildMenuRow(
      icon: Icons.verified_user_outlined,
      title: 'KYC Verification',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
        child: Text(
          profileStatus,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor),
        ),
      ),
      onTap: () => context.go(AppRoutes.kycVerification),
    );
  }

  Widget _buildLockedRewardsRow() {
    return Opacity(
      opacity: 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2D2513),
                  ),
                  child: const Icon(Icons.card_giftcard, color: Color(0xFFF7CD57), size: 18),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rewards & Referrals',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "You've earned Rs.420",
                        style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 70),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF2A2010),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 10, color: Color(0xFFF7CD57)),
                      const SizedBox(width: 4),
                      const Text(
                        'Locked',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFF7CD57)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionStatement() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFFF7CD57), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Transaction Statement',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Download your buy, sell, or redeem transaction statements as PDF.',
            style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'From Date',
                  value: _statementFromDate,
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateField(
                  label: 'To Date',
                  value: _statementToDate,
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          if (_statementError != null) ...[
            const SizedBox(height: 8),
            Text(_statementError!, style: const TextStyle(fontSize: 10, color: Color(0xFFFF4D4D))),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatementButton('buy', 'BUY'),
              const SizedBox(width: 6),
              _buildStatementButton('sell', 'SELL'),
              const SizedBox(width: 6),
              _buildStatementButton('redeem', 'REDEEM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({required String label, required DateTime? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16181A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Text(
              value != null
                  ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                  : 'Select',
              style: TextStyle(
                fontSize: 11,
                color: value != null ? Colors.white : const Color(0xFF7E7E7E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_statementFromDate ?? now.subtract(const Duration(days: 30))) : (_statementToDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _statementFromDate = picked;
        } else {
          _statementToDate = picked;
        }
        _statementError = null;
      });
    }
  }

  Widget _buildStatementButton(String type, String label) {
    final isDownloading = _downloadingStatement == type;
    final hasDates = _statementFromDate != null && _statementToDate != null;
    return Expanded(
      child: GestureDetector(
        onTap: hasDates && !isDownloading ? () => _downloadStatement(type) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isDownloading
                ? null
                : const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35)]),
            color: isDownloading ? const Color(0xFF2A2010) : null,
          ),
          child: Center(
            child: Text(
              isDownloading ? '...' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDownloading ? const Color(0xFFF7CD57) : const Color(0xFF1A1710),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadStatement(String type) async {
    if (_statementFromDate == null || _statementToDate == null) return;
    setState(() {
      _downloadingStatement = type;
      _statementError = null;
    });
    try {
      final uniqueId = _resolveUniqueId();
      if (uniqueId.isEmpty) {
        setState(() { _statementError = 'User not found.'; _downloadingStatement = null; });
        return;
      }
      final api = AugmontApi(ref.read(dioAugmontProvider));
      final result = await api.downloadTransactionPdf(
        type: type,
        uniqueId: uniqueId,
        fromDate: '${_statementFromDate!.year}-${_statementFromDate!.month.toString().padLeft(2, '0')}-${_statementFromDate!.day.toString().padLeft(2, '0')}',
        toDate: '${_statementToDate!.year}-${_statementToDate!.month.toString().padLeft(2, '0')}-${_statementToDate!.day.toString().padLeft(2, '0')}',
      );
      if (!mounted) return;
      if (result['ok'] == true && result['bytes'] != null) {
        final bytes = result['bytes'] as List<int>;
        final fileName = result['fileName'] as String;
        await _savePdf(bytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Transaction Statement has Downloaded', style: TextStyle(fontSize: 13)),
                ],
              ),
              backgroundColor: const Color(0xFF1B5E20),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() { _statementError = result['message']?.toString() ?? 'Failed to download.'; });
      }
    } catch (e) {
      if (mounted) setState(() { _statementError = 'Failed to download $type statement.'; });
    }
    if (mounted) setState(() => _downloadingStatement = null);
  }

  Future<void> _savePdf(List<int> bytes, String fileName) async {
    try {
      await downloadPdf(bytes, fileName);
    } catch (_) {
      // Fallback
      try {
        final tempDir = await _getTempDir();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], subject: fileName);
      } catch (e) {
        if (mounted) setState(() { _statementError = 'Failed to save PDF.'; });
      }
    }
  }

  Future<Directory> _getTempDir() async {
    try {
      return Directory.systemTemp;
    } catch (_) {
      return Directory('/tmp');
    }
  }

  Widget _buildNotificationToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: Color(0xFFF7CD57), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
            child: Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _notificationsEnabled ? const Color(0xFFF7CD57) : const Color(0xFFA2A2A2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _notificationsEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1F2124)),
              child: Icon(icon, color: const Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: Color(0xFF7E7E7E), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          ref.read(authProvider.notifier).logout();
          context.go(AppRoutes.login);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF0F1416),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Color(0xFFFF3700), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Sign Out',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF3700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _kycStatusLabel(String? status) {
    final value = (status ?? '').trim().toLowerCase();
    if (value == 'approved' || value == 'verified') return 'Verified';
    if (value == 'pending') return 'Pending';
    return 'Not Started';
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }
}
