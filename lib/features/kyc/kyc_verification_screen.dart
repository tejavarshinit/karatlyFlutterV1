import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/api/transbank_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  static const _completionModalKeyPrefix = 'kycCompletionModalShown:';

  bool _loading = true;
  bool _kycApproved = false;
  String _panNumber = '';
  bool _aadhaarVerified = false;
  List<Map<String, dynamic>> _banks = [];
  bool _bankVerified = false;
  bool _showCompletionModal = false;
  bool _previousAllDone = false;

  String? _approvalMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _resolveUniqueId() {
    final augmontUserRaw = LocalStorageService.getAugmontUser();
    if (augmontUserRaw != null && augmontUserRaw.isNotEmpty) {
      try {
        final augmontUser = jsonDecode(augmontUserRaw) as Map<String, dynamic>;
        final uniqueId = augmontUser['uniqueId']?.toString().trim() ?? '';
        if (uniqueId.isNotEmpty) return uniqueId;
      } catch (_) {}
    }

    final profile = LocalStorageService.getUserProfile();
    final uniqueId = profile?['augmontUniqueId']?.toString().trim() ?? profile?['uniqueId']?.toString().trim() ?? '';
    if (uniqueId.isNotEmpty) return uniqueId;

    return LocalStorageService.getUserUniqueId() ?? '';
  }

  Future<void> _refreshAuthFromToken() async {
    await ref.read(authProvider.notifier).refreshAfterKyc();
  }

  Future<void> _load() async {
    try {
      final uniqueId = _resolveUniqueId();
      if (uniqueId.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final profile = LocalStorageService.getUserProfile() ?? {};
      final currentAadhaarVerified = profile['aadhaarVerified'] == true;

      final augmont = AugmontApi(ref.read(dioAugmontProvider));
      final results = await Future.wait([
        augmont.fetchAugmontUserBanks(uniqueId),
        augmont.fetchAugmontKycProfile(uniqueId),
      ]);

      final banksRes = results[0];
      final kycRes = results[1];

      final banks = _parseBanks(banksRes['banks']);
      final bankVerified = banks.isNotEmpty;
      final kycProfile = _asMap(kycRes['kycProfile']);
      final approved = _normalizeStatus(kycProfile?['status']) == 'approved';
      final pan = kycProfile?['panNumber']?.toString().trim() ?? '';

      if (pan.isNotEmpty) {
        await LocalStorageService.setUserPan(pan);
      }

      if (!mounted) return;
      setState(() {
        _kycApproved = approved;
        _panNumber = pan;
        _aadhaarVerified = currentAadhaarVerified;
        _banks = banks;
        _bankVerified = bankVerified;
        _loading = false;
      });

      _maybeShowCompletionModal();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _kycApproved = false;
        _panNumber = '';
        _aadhaarVerified = LocalStorageService.getUserProfile()?['aadhaarVerified'] == true;
        _banks = [];
        _bankVerified = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseBanks(dynamic raw) {
    final source = raw is List ? raw : const [];
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _normalizeStatus(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  void _maybeShowCompletionModal() {
    final uniqueId = _resolveUniqueId();
    final key = '$_completionModalKeyPrefix${uniqueId.isEmpty ? 'current-user' : uniqueId}';
    final allDone = _kycApproved && _aadhaarVerified && _bankVerified;
    if (!_previousAllDone && allDone && !LocalStorageService.getUserProfile().toString().contains(key)) {
      // Mirror the reference behavior by showing the congratulatory modal once.
      setState(() {
        _showCompletionModal = true;
      });
      final profile = LocalStorageService.getUserProfile() ?? {};
      profile[key] = true;
      LocalStorageService.setUserProfile(profile);
    }
    _previousAllDone = allDone;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9755, -0.3792),
              radius: 1.04,
              colors: [Color(0xFF4A3A1E), Colors.black],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFF7CD57)),
          ),
        ),
      );
    }

    final allDone = _kycApproved && _aadhaarVerified && _bankVerified;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    if (_approvalMessage != null) ...[
                      _buildGateBanner(_approvalMessage!),
                      const SizedBox(height: 12),
                    ],
                    _buildTopBanner(allDone),
                    const SizedBox(height: 14),
                    _buildSection(
                      icon: Icons.credit_card,
                      title: 'PAN Verification',
                      subtitle: 'Validate your PAN for KYC compliance',
                      verified: _kycApproved,
                      defaultOpen: !_kycApproved,
                      child: PanSection(
                        uniqueId: _resolveUniqueId(),
                        kycApproved: _kycApproved,
                        panNumber: _panNumber,
                        onVerified: (verifiedPan) async {
                          setState(() {
                            _kycApproved = true;
                            _panNumber = verifiedPan;
                          });
                          await LocalStorageService.setUserPan(verifiedPan);
                          await _refreshAuthFromToken();
                          _maybeShowCompletionModal();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      icon: Icons.person,
                      title: 'Aadhaar Verification',
                      subtitle: 'Verify via OTP sent to Aadhaar-linked mobile',
                      verified: _aadhaarVerified,
                      defaultOpen: !_aadhaarVerified && _kycApproved,
                      child: AadhaarSection(
                        uniqueId: _resolveUniqueId(),
                        verified: _aadhaarVerified,
                        onVerified: () async {
                          setState(() => _aadhaarVerified = true);
                          await _refreshAuthFromToken();
                          _maybeShowCompletionModal();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      icon: Icons.account_balance,
                      title: 'Bank Account',
                      subtitle: 'Required for gold sell payouts',
                      verified: _bankVerified,
                      defaultOpen: !_bankVerified && _kycApproved && _aadhaarVerified,
                      child: BankSection(
                        uniqueId: _resolveUniqueId(),
                        banks: _banks,
                        onVerified: () async {
                          final augmont = AugmontApi(ref.read(dioAugmontProvider));
                          final uniqueId = _resolveUniqueId();
                          final refreshed = await augmont.fetchAugmontUserBanks(uniqueId);
                          if (!mounted) return;
                          final nextBanks = _parseBanks(refreshed['banks']);
                          setState(() {
                            _banks = nextBanks;
                            _bankVerified = nextBanks.isNotEmpty;
                          });
                          await _refreshAuthFromToken();
                          _maybeShowCompletionModal();
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.home),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4E4E4E)),
                          color: const Color(0xFF1A1710),
                        ),
                        child: Center(
                          child: Text(
                            allDone ? 'Go to Dashboard →' : 'Complete later — Go to Dashboard',
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showCompletionModal)
                KycCompletionModal(
                  onClose: () {
                    setState(() => _showCompletionModal = false);
                    context.go(AppRoutes.home);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            const Text('KYC Verification', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
          ],
        ),
        Row(
          children: [
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: allDoneState() ? const Color(0xFF032101) : const Color(0xFF1D170D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: allDoneState() ? const Color(0xFF0C9100) : const Color(0xFFE8B438)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, size: 10, color: allDoneState() ? const Color(0xFF15EE01) : const Color(0xFFF7CD57)),
                  const SizedBox(width: 4),
                  Text(
                    allDoneState() ? 'Verified' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      color: allDoneState() ? const Color(0xFF15EE01) : const Color(0xFFF7CD57),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildNotificationButton(context),
          ],
        ),
      ],
    );
  }

  bool allDoneState() => _kycApproved && _aadhaarVerified && _bankVerified;

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.notifications),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1D170D),
          border: Border.all(color: const Color(0xFFE8B438)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 14),
            const Positioned(
              right: 4,
              top: 4,
              child: SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEE0105), shape: BoxShape.circle))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF7CD57).withOpacity(0.25)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF432F12), Color(0xFF120D05)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE784), Color(0xFFC88912)]),
            ),
            child: const Icon(Icons.shield, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Approval required', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 10, color: Color(0xFFC8BFAE), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner(bool allDone) {
    if (allDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF4CD676).withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF4CD676).withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CD676), size: 22),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All KYC steps completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CD676))),
                SizedBox(height: 2),
                Text('Your account is fully verified', style: TextStyle(fontSize: 10, color: Color(0x66FFFFFF))),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B438).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.15)),
      ),
      child: const Text(
        'Complete the steps below in any order. Each step is independent - tap to expand.',
        style: TextStyle(fontSize: 12, color: Color(0xFFF7CD57), height: 1.4),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool verified,
    required Widget child,
    bool defaultOpen = false,
  }) {
    return KycAccordion(
      icon: icon,
      title: title,
      subtitle: subtitle,
      verified: verified,
      defaultOpen: defaultOpen,
      child: child,
    );
  }
}

class KycAccordion extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool verified;
  final bool defaultOpen;
  final Widget child;

  const KycAccordion({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.verified,
    required this.defaultOpen,
    required this.child,
  });

  @override
  State<KycAccordion> createState() => _KycAccordionState();
}

class _KycAccordionState extends State<KycAccordion> {
  late bool _open = widget.defaultOpen;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.verified ? const Color(0xFF4CD676).withOpacity(0.2) : const Color(0xFF2E2E2E)),
        color: widget.verified ? const Color(0xFF4CD676).withOpacity(0.05) : const Color(0xFF0F1416),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.verified ? const Color(0xFF4CD676).withOpacity(0.15) : const Color(0xFF38342C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.verified ? Icons.check_circle : widget.icon, color: widget.verified ? const Color(0xFF4CD676) : const Color(0xFFF7CD57), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.verified ? const Color(0xFF0D3320) : const Color(0xFF3D2E00),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.verified ? 'Verified' : 'Pending',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.verified ? const Color(0xFF4CD676) : const Color(0xFFF7CD57)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF7E7E7E)),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2E2E2E))),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class KycCompletionModal extends StatelessWidget {
  final VoidCallback onClose;

  const KycCompletionModal({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: Container(
            width: 342,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.35)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF503B15), Color(0xFF1C1408), Color(0xFF080603)],
              ),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 16))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFFFE784), Color(0xFFC88912)]),
                  ),
                  child: const Icon(Icons.shield, color: Color(0xFF11130F), size: 30),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2513),
                    border: Border.all(color: const Color(0xFFF7CD57).withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'KYC Verified',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Congratulations! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are now a KYC Verified Customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFFD5C7A8), height: 1.5),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      gradient: LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)]),
                    ),
                    child: const Text('Start Investing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PanSection extends StatefulWidget {
  final String uniqueId;
  final bool kycApproved;
  final String panNumber;
  final ValueChanged<String> onVerified;

  const PanSection({
    super.key,
    required this.uniqueId,
    required this.kycApproved,
    required this.panNumber,
    required this.onVerified,
  });

  @override
  State<PanSection> createState() => _PanSectionState();
}

class _PanSectionState extends State<PanSection> {
  final _panController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showOcr = false;
  XFile? _ocrFile;
  Uint8List? _ocrPreviewBytes;
  bool _ocrLoading = false;
  String? _ocrError;

  @override
  void initState() {
    super.initState();
    _panController.text = widget.panNumber;
  }

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pan = _panController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final mobile = LocalStorageService.getUserProfile()?['mobileNumber']?.toString() ?? LocalStorageService.getUserPhone() ?? '';

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
      setState(() => _error = 'Enter a valid PAN (e.g. ABCDE1234F)');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter name as per PAN card');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final api = TransbankApi(ProviderScope.containerOf(context).read(dioAugmontProvider));
    final result = await api.transbankValidatePan(panNumber: pan, name: name, mobile: mobile);
    if (!mounted) return;

    if (result['ok'] != true || result['isValid'] != true) {
      setState(() {
        _loading = false;
        final rawCode = _nestedCode(result);
        if (rawCode == 2) {
          _showOcr = true;
        } else {
          _error = result['message']?.toString() ?? 'PAN verification failed. Please try again.';
        }
      });
      return;
    }

    final augmont = AugmontApi(ProviderScope.containerOf(context).read(dioAugmontProvider));
    final response = await augmont.updateAugmontKyc(
      uniqueId: widget.uniqueId,
      request: {
        'panNumber': pan,
        'nameAsPerPan': name,
        'status': 'approved',
      },
    );
    if (!mounted) return;

    setState(() => _loading = false);
    if (response['ok'] == true) {
      widget.onVerified(pan);
    } else {
      setState(() => _error = response['message']?.toString() ?? 'PAN submission failed.');
    }
  }

  Future<void> _pickOcrImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (!mounted || file == null) return;
      setState(() {
        _ocrFile = file;
        _ocrPreviewBytes = null;
        _ocrError = null;
      });
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _ocrPreviewBytes = bytes);
  }

  int? _nestedCode(Map<String, dynamic> result) {
    try {
      final raw = result['raw'] as Map<String, dynamic>?;
      final code = raw?['code'];
      return int.tryParse(code?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _verifyOcr() async {
    if (_ocrFile == null) {
      setState(() => _ocrError = 'Please select your PAN card image.');
      return;
    }

    setState(() {
      _ocrLoading = true;
      _ocrError = null;
    });

    final dio = ProviderScope.containerOf(context).read(dioAugmontProvider);
    final transbank = TransbankApi(dio);
    final result = await transbank.transbankPanOcr(
      file: await MultipartFile.fromBytes(_ocrPreviewBytes ?? await _ocrFile!.readAsBytes(), filename: _ocrFile!.name),
      uniqueId: widget.uniqueId,
      mobile: LocalStorageService.getUserProfile()?['mobileNumber']?.toString() ?? LocalStorageService.getUserPhone() ?? '',
    );

    if (!mounted) return;
    if (result['ok'] != true) {
      setState(() {
        _ocrLoading = false;
        _ocrError = result['message']?.toString() ?? 'OCR verification failed. Please try again.';
      });
      return;
    }

    final panNumber = result['panNumber']?.toString() ?? _panController.text.trim().toUpperCase();
    final name = result['name']?.toString() ?? _nameController.text.trim();

    final augmont = AugmontApi(dio);
    final response = await augmont.updateAugmontKyc(
      uniqueId: widget.uniqueId,
      request: {
        'panNumber': panNumber,
        'nameAsPerPan': name,
        'status': 'approved',
      },
    );

    if (!mounted) return;
    setState(() => _ocrLoading = false);
    if (response['ok'] == true) {
      widget.onVerified(panNumber);
    } else {
      setState(() => _ocrError = response['message']?.toString() ?? 'PAN submission failed after OCR.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kycApproved) {
      return const Text(
        'PAN verified with Augmont.',
        style: TextStyle(fontSize: 12, color: Color(0xFF4CD676)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7CD57).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.15)),
          ),
          child: const Text(
            'PAN is required for KYC compliance and purchases above ₹1,000.',
            style: TextStyle(fontSize: 10, color: Color(0xFFF7CD57)),
          ),
        ),
        const SizedBox(height: 12),
        if (_showOcr) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1710),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verify via PAN Card Image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
                const SizedBox(height: 4),
                const Text(
                  "We couldn't verify your PAN automatically. Upload a clear PAN card photo to continue.",
                  style: TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickOcrImage,
                  child: Container(
                    height: 96,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7CD57).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.35), style: BorderStyle.solid),
                    ),
                    child: _ocrPreviewBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, color: Color(0xFFF7CD57)),
                              SizedBox(height: 6),
                              Text('Tap to select PAN card image', style: TextStyle(fontSize: 11, color: Color(0xFFF7CD57))),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_ocrPreviewBytes!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                if (_ocrError != null) ...[
                  const SizedBox(height: 8),
                  Text(_ocrError!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
                ],
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _ocrLoading ? null : _verifyOcr,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)]),
                    ),
                    child: Center(
                      child: _ocrLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Verify PAN via Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          _inputField(controller: _panController, label: 'PAN Number', hint: 'ABCDE1234F', maxLength: 10, toUpperCase: true),
          const SizedBox(height: 10),
          _inputField(controller: _nameController, label: 'Name as per PAN', hint: 'FULL NAME AS ON PAN', toUpperCase: true),
          const SizedBox(height: 10),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)]),
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Verify & Submit PAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool toUpperCase = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: (value) {
            if (toUpperCase && value != value.toUpperCase()) {
              controller.value = controller.value.copyWith(
                text: value.toUpperCase(),
                selection: TextSelection.collapsed(offset: value.length),
              );
            }
            setState(() => _error = null);
          },
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: const TextStyle(color: Color(0xFF4E4E4E), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1A1710),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4E4E4E))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4E4E4E))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8B438))),
          ),
        ),
      ],
    );
  }
}

class AadhaarSection extends StatefulWidget {
  final String uniqueId;
  final bool verified;
  final VoidCallback onVerified;

  const AadhaarSection({
    super.key,
    required this.uniqueId,
    required this.verified,
    required this.onVerified,
  });

  @override
  State<AadhaarSection> createState() => _AadhaarSectionState();
}

class _AadhaarSectionState extends State<AadhaarSection> {
  String? _verificationMode;
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();
  String _stage = 'enter';
  bool _loading = false;
  String? _error;
  String? _success;
  String? _sessionId;
  int _countdown = 0;
  bool _ocrLoading = false;
  Map<String, dynamic>? _ocrResult;
  String? _ocrError;

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_countdown > 0) return;
    setState(() => _countdown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _countdown <= 0) return false;
      setState(() => _countdown -= 1);
      return _countdown > 0;
    });
  }

  Future<void> _sendOtp() async {
    final aadhaar = _aadhaarController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (aadhaar.length != 12) {
      setState(() => _error = 'Enter a valid 12-digit Aadhaar number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final api = TransbankApi(ProviderScope.containerOf(context).read(dioAugmontProvider));
    final result = await api.transbankAadhaarGenerateOtp(aadhaar);
    if (!mounted) return;

    setState(() => _loading = false);
    if (result['ok'] == true) {
      setState(() {
        _stage = 'otp';
        _sessionId = result['sessionId']?.toString();
        _success = 'OTP sent successfully';
      });
      _startCountdown();
    } else {
      setState(() => _error = result['message']?.toString() ?? 'Could not send OTP.');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim().replaceAll(RegExp(r'\D'), '');
    final aadhaar = _aadhaarController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (otp.length != 6) {
      setState(() => _error = 'Enter a valid 6-digit OTP');
      return;
    }
    if ((_sessionId ?? '').isEmpty) {
      setState(() => _error = 'Session expired. Please resend OTP.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final api = TransbankApi(ProviderScope.containerOf(context).read(dioAugmontProvider));
    final result = await api.transbankAadhaarSubmitOtp(
      aadhaarNumber: aadhaar,
      otp: otp,
      sessionId: _sessionId!,
      uniqueId: widget.uniqueId,
    );

    if (!mounted) return;
    if (result['ok'] == true) {
      final raw = result['raw'] as Map<String, dynamic>?;
      final photo = raw?['photo']?.toString() ??
          (raw?['data'] as Map<String, dynamic>?)?['photo']?.toString() ??
          (raw?['payload'] as Map<String, dynamic>?)?['photo']?.toString();
      if (photo != null && photo.isNotEmpty) {
        final formatted = photo.startsWith('data:') ? photo : 'data:image/jpeg;base64,$photo';
        await LocalStorageService.setProfilePhoto(formatted);
      }
      setState(() => _loading = false);
      widget.onVerified();
    } else {
      setState(() {
        _loading = false;
        _error = result['message']?.toString() ?? 'OTP verification failed.';
      });
    }
  }

  Future<void> _pickAndOcrAadhaar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _ocrLoading = true;
      _ocrError = null;
      _ocrResult = null;
    });

    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);

    final api = TransbankApi(ProviderScope.containerOf(context).read(dioAugmontProvider));
    final result = await api.transbankAadhaarOcr(
      base64Image: base64Image,
      uniqueId: widget.uniqueId,
    );

    if (!mounted) return;

    setState(() => _ocrLoading = false);
    if (result['ok'] == true) {
      setState(() => _ocrResult = result);
      widget.onVerified();
    } else {
      setState(() => _ocrError = result['message']?.toString() ?? 'OCR failed. Please try again with a clearer photo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verified) {
      return const Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Color(0xFF4CD676)),
          SizedBox(width: 6),
          Text('Aadhaar verified successfully.', style: TextStyle(fontSize: 12, color: Color(0xFF4CD676))),
        ],
      );
    }

    if (_verificationMode == null) {
      return _buildChooser();
    }

    if (_verificationMode == 'manual') {
      return _buildManualMode();
    }

    return _buildAutoMode();
  }

  Widget _buildChooser() {
    return Row(
      children: [
        Expanded(child: _chooserButton(
          icon: Icons.smartphone,
          label: 'AUTO',
          subtitle: 'Verify via OTP sent to your Aadhaar-linked mobile',
          onTap: () => setState(() => _verificationMode = 'auto'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _chooserButton(
          icon: Icons.camera_alt,
          label: 'MANUAL',
          subtitle: 'Upload Aadhaar image \u2014 OCR will extract details',
          onTap: () => setState(() => _verificationMode = 'manual'),
        )),
      ],
    );
  }

  Widget _chooserButton({required IconData icon, required String label, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1710),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFE8EEF5), Color(0xFF8E9AAA)]),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF11130F)),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload a clear photo of your Aadhaar card', style: TextStyle(fontSize: 10, color: Color(0x80FFFFFF))),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _ocrLoading ? null : _pickAndOcrAadhaar,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.3)),
              color: const Color(0xFF1A1710),
            ),
            child: _ocrLoading
                ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF7CD57))))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 16, color: Color(0xFFF7CD57)),
                      SizedBox(width: 8),
                      Text('Tap to capture Aadhaar', style: TextStyle(fontSize: 12, color: Color(0xFFF7CD57))),
                    ],
                  ),
          ),
        ),
        if (_ocrError != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x33EF5350)),
              color: const Color(0x0DEF5350),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 12, color: Color(0xFFEF5350)),
                const SizedBox(width: 6),
                Expanded(child: Text(_ocrError!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350)))),
              ],
            ),
          ),
        ],
        if (_ocrResult != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x334CD676)),
              color: const Color(0x0D4CD676),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_ocrResult!['name'] != null)
                  _ocrDetailRow('Name', _ocrResult!['name'].toString()),
                if (_ocrResult!['cardNumber'] != null)
                  _ocrDetailRow('Aadhaar', _ocrResult!['cardNumber'].toString()),
                if (_ocrResult!['dateOfBirth'] != null)
                  _ocrDetailRow('DOB', _ocrResult!['dateOfBirth'].toString()),
                if (_ocrResult!['gender'] != null)
                  _ocrDetailRow('Gender', _ocrResult!['gender'].toString()),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() {
            _verificationMode = 'auto';
            _ocrError = null;
            _ocrResult = null;
          }),
          child: const Center(
            child: Text('Switch to OTP verification instead', style: TextStyle(fontSize: 10, color: Color(0xB3F7CD57), decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }

  Widget _ocrDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11, color: Color(0xFF4CD676))),
    );
  }

  Widget _buildAutoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7CD57).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.15)),
          ),
          child: const Text(
            'An OTP will be sent to the mobile number linked with your Aadhaar.',
            style: TextStyle(fontSize: 10, color: Color(0xFFF7CD57)),
          ),
        ),
        const SizedBox(height: 10),
        if (_stage == 'enter') ...[
          _inputField(
            controller: _aadhaarController,
            label: 'Aadhaar Number',
            hint: '123456789012',
            keyboardType: TextInputType.number,
            maxLength: 12,
          ),
          const SizedBox(height: 8),
          if (_success != null) Text(_success!, style: const TextStyle(fontSize: 11, color: Color(0xFF4CD676))),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _verificationMode = 'manual';
                _error = null;
                _ocrError = null;
              }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x33E8B438)),
                  color: const Color(0x0DE8B438),
                ),
                child: const Center(child: Text('Please try manually', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFF7CD57)))),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _goldButton(label: 'Send OTP', loading: _loading, onTap: _sendOtp),
        ] else ...[
          if (_success != null) Text(_success!, style: const TextStyle(fontSize: 11, color: Color(0xFF4CD676))),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
          ],
          const SizedBox(height: 6),
          _inputField(
            controller: _otpController,
            label: 'Enter OTP',
            hint: '6-digit OTP',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 8),
          _goldButton(label: 'Verify OTP', loading: _loading, onTap: _verifyOtp),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _loading ? null : () { _sendOtp(); },
                  child: const Center(child: Text('Resend OTP', style: TextStyle(fontSize: 10, color: Color(0x4DFFFFFF)))),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _stage = 'enter'; _otpController.clear(); _error = null; }),
                  child: const Center(child: Text('Change number', style: TextStyle(fontSize: 10, color: Color(0x4DFFFFFF)))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() {
              _verificationMode = 'manual';
              _error = null;
              _ocrError = null;
            }),
            child: const Center(
              child: Text('Switch to Manual (Upload Aadhaar image)', style: TextStyle(fontSize: 10, color: Color(0xB3F7CD57), decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: (value) {
            if (keyboardType == TextInputType.number) {
              controller.value = controller.value.copyWith(
                text: value.replaceAll(RegExp(r'\D'), ''),
                selection: TextSelection.collapsed(offset: value.replaceAll(RegExp(r'\D'), '').length),
              );
            }
            setState(() {
              _error = null;
            });
          },
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: const TextStyle(color: Color(0xFF4E4E4E), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1A1710),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4E4E4E))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4E4E4E))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8B438))),
          ),
        ),
      ],
    );
  }

  Widget _goldButton({required String label, required bool loading, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)]),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ),
    );
  }
}

class BankSection extends StatefulWidget {
  final String uniqueId;
  final List<Map<String, dynamic>> banks;
  final VoidCallback onVerified;

  const BankSection({
    super.key,
    required this.uniqueId,
    required this.banks,
    required this.onVerified,
  });

  @override
  State<BankSection> createState() => _BankSectionState();
}

class _BankSectionState extends State<BankSection> {
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseBanks(dynamic raw) {
    final source = raw is List ? raw : const [];
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _extractBankId(Map<String, dynamic> bank) {
    return (bank['provider_bank_id'] ?? bank['userBankId'] ?? bank['bankId'] ?? bank['id'] ?? '')
        .toString()
        .trim();
  }

  String _maskAccount(String account) {
    final cleaned = account.replaceAll(' ', '');
    if (cleaned.length <= 4) return '****$cleaned';
    return '****${cleaned.substring(cleaned.length - 4)}';
  }

  Future<void> _submit() async {
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();

    if (accountName.isEmpty || accountNumber.isEmpty || ifsc.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      setState(() => _error = 'Enter a valid IFSC (e.g. SBIN0001234)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final transbank = TransbankApi(ProviderScope.containerOf(context).read(dioAugmontProvider));
    final result = await transbank.transbankValidateBankAccount(
      accountName: accountName,
      accountNumber: accountNumber,
      ifscCode: ifsc,
      uniqueId: widget.uniqueId,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (result['ok'] != true || result['isValid'] == false) {
      setState(() => _error = result['message']?.toString() ?? 'Bank validation failed.');
      return;
    }

    final augmont = AugmontApi(ProviderScope.containerOf(context).read(dioAugmontProvider));

    final createResult = await augmont.createAugmontUserBank(
      uniqueId: widget.uniqueId,
      request: {
        'accountNumber': accountNumber,
        'accountName': accountName,
        'ifscCode': ifsc,
      },
    );

    if (!mounted) return;
    if (createResult['ok'] != true) {
      setState(() => _error = createResult['message']?.toString() ?? 'Failed to save bank details.');
      return;
    }

    final banksRes = await augmont.fetchAugmontUserBanks(widget.uniqueId);
    final latestBanks = _parseBanks(banksRes['banks']);
    if (latestBanks.length == 1) {
      final bankId = _extractBankId(latestBanks.first);
      if (bankId.isNotEmpty) {
        await augmont.setPrimaryAugmontUserBank(uniqueId: widget.uniqueId, userBankId: bankId);
        final bankMap = Map<String, dynamic>.from(latestBanks.first);
        bankMap['isPrimary'] = true;
        bankMap['is_primary'] = true;
        await LocalStorageService.setPrimaryBankId(bankId);
        await LocalStorageService.setPrimaryBank(jsonEncode(bankMap));
      }
    } else {
      final apiPrimary = latestBanks.where((item) => item['isPrimary'] == true || item['is_primary'] == true).toList();
      if (apiPrimary.isNotEmpty) {
        final primaryId = _extractBankId(apiPrimary.first);
        if (primaryId.isNotEmpty) {
          await LocalStorageService.setPrimaryBankId(primaryId);
          await LocalStorageService.setPrimaryBank(jsonEncode(apiPrimary.first));
        }
      }
    }

    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.banks.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CD676).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4CD676).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Existing accounts', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4CD676))),
                const SizedBox(height: 8),
                ...widget.banks.map(
                  (bank) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${bank['accountName'] ?? bank['account_holder_name'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_maskAccount((bank['accountNumber'] ?? bank['account_number'] ?? '').toString())} · ${bank['ifscCode'] ?? bank['ifsc_code'] ?? ''}',
                          style: const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text('Add another account below', style: TextStyle(fontSize: 10, color: Color(0x80FFFFFF))),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7CD57).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8B438).withOpacity(0.15)),
          ),
          child: const Text(
            'Bank account is verified in real-time before being added.',
            style: TextStyle(fontSize: 10, color: Color(0xFFF7CD57)),
          ),
        ),
        const SizedBox(height: 10),
        _field(
          controller: _accountNameController,
          label: 'Account Holder Name',
          hint: 'As per bank records',
        ),
        const SizedBox(height: 10),
        _field(
          controller: _accountNumberController,
          label: 'Account Number',
          hint: 'Enter account number',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _ifscController,
          label: 'IFSC Code',
          hint: 'SBIN0001234',
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
        ],
        const SizedBox(height: 10),
        _goldButton(label: 'Validate & Add Bank', loading: _loading, onTap: _submit),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (value) {
            if (keyboardType == TextInputType.number) {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              controller.value = controller.value.copyWith(text: digits, selection: TextSelection.collapsed(offset: digits.length));
            }
            setState(() => _error = null);
          },
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4E4E4E), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1A1710),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4E4E4E))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4E4E4E))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8B438))),
          ),
        ),
      ],
    );
  }

  Widget _goldButton({required String label, required bool loading, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)]),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ),
    );
  }
}
