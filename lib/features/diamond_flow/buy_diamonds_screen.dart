import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/api/cashfree_api.dart';
import '../../core/api/diamond_api.dart';
import '../../core/api/dio_client.dart';
import '../../core/models/diamond_model.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';
import 'widgets/diamond_card.dart';
import 'widgets/diamond_cart_thumb.dart';

class BuyDiamondsScreen extends ConsumerStatefulWidget {
  const BuyDiamondsScreen({super.key});

  @override
  ConsumerState<BuyDiamondsScreen> createState() => _BuyDiamondsScreenState();
}

class _BuyDiamondsScreenState extends ConsumerState<BuyDiamondsScreen>
    with SingleTickerProviderStateMixin {
  // ── Step state ────────────────────────────────────────────────────────────
  String _step = 'filters';
  String _activeFilterTab = 'main';

  // ── Loading / error ───────────────────────────────────────────────────────
  bool _loadingProducts = false;
  bool _loadingCart = false;
  String _error = '';

  // ── Multi-select filter state (flat Set like React) ──────────────────────
  final Set<String> _selectedFilters = {};

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  bool _hasFilter(String filter) => _selectedFilters.contains(filter);

  // ── Main filter state ─────────────────────────────────────────────────────
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();
  String _sortOrder = 'Low to high';
  bool _video = true;
  bool? _buyback; // null = neutral, true = Yes, false = No
  final TextEditingController _minCaratCtrl = TextEditingController();
  final TextEditingController _maxCaratCtrl = TextEditingController();
  bool _showCaratError = false;
  Timer? _caratErrorDebounce;
  Timer? _caratErrorClear;
  Timer? _bannerTimer;

  bool get _isCaratValid {
    final min = double.tryParse(_minCaratCtrl.text);
    final max = double.tryParse(_maxCaratCtrl.text);
    if (min == null || max == null) return false;
    return min > 0 && max >= min;
  }

  // ── Advanced filter state ─────────────────────────────────────────────────
  final TextEditingController _advMinLenCtrl = TextEditingController(text: '0');
  final TextEditingController _advMaxLenCtrl = TextEditingController(text: '0');
  final TextEditingController _advMinWidthCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMaxWidthCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMinDepthCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMaxDepthCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMinLwCtrl = TextEditingController(text: '0');
  final TextEditingController _advMaxLwCtrl = TextEditingController(text: '0');
  final TextEditingController _advMinCrownCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMaxCrownCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMinTableCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMaxTableCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMinPavilionCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMaxPavilionCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMinPriceUsdCtrl =
      TextEditingController(text: '0');
  final TextEditingController _advMaxPriceUsdCtrl =
      TextEditingController(text: '0');

  // ── Products ──────────────────────────────────────────────────────────────
  List<DiamondProduct> _products = [];
  int _totalProducts = 0;
  int _currentPage = 0;
  bool _hasMore = false;

  // ── Cart ──────────────────────────────────────────────────────────────────
  List<DiamondCartItem> _cartItems = [];
  Set<String> _selectedCartItemIds = {};
  bool _allSelected = true;
  bool _addingToCart = false;

  // ── Payment ───────────────────────────────────────────────────────────────

  // ── Processing animation ──────────────────────────────────────────────────
  late AnimationController _processingAnimController;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0084FF);
  static const Color _accent = Color(0xFF3AC7FF);
  static const Color _bgDark = Color(0xFF293341);
  static const Color _cardBorder = Color(0xFF2E2E2E);
  static const Color _success = Color(0xFF15EE01);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  // ── Filter option lists (matching React constants) ────────────────────────
  static const List<String> _shapeOptions = [
    'Round',
    'Oval',
    'Pear',
    'Radiant',
    'Cushion',
    'Sq.Cushion',
    'Emerald',
    'Heart',
    'Princess',
    'Marquise',
    'Asscher',
  ];
  static const List<String> _clarityOptions = [
    'FL',
    'IF',
    'VVS1',
    'VVS2',
    'VS1',
    'VS2',
    'SI1',
    'SI2',
    'I1',
    'I2',
    'I3',
  ];
  static const List<String> _colorOptions = [
    'White',
    'Yellow',
    'Pink',
    'Blue',
    'Red',
    'Green',
    'Purple',
    'Orange',
    'Violet',
    'Grey',
    'Black',
    'Brown',
    'Cognac',
    'Chameleon',
    'Champagne',
    'Salt & Pepper',
    'Others',
  ];
  static const List<String> _cutOptions = [
    '8X',
    'Ideal',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
    'Poor',
    'None',
  ];
  static const List<String> _polishOptions = [
    '8X',
    'Ideal',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
    'Poor',
    'None',
  ];
  static const List<String> _symmetryOptions = [
    '8X',
    'Ideal',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
    'Poor',
    'None',
  ];
  static const List<String> _fluorescenceOptions = [
    'None',
    'Faint',
    'Medium',
    'Strong',
    'Very Strong',
  ];
  static const List<String> _certificateOptions = [
    'GIA',
    'IGI',
    'NO-Cert',
  ];

  DiamondApi _diamondApi() {
    final dio = ref.read(dioClientProvider).dio;
    return DiamondApi(dio);
  }

  @override
  void initState() {
    super.initState();
    _processingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _startBannerTimer();
    _fetchCart();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _step == 'cart') setState(() {});
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _processingAnimController.dispose();
    _caratErrorDebounce?.cancel();
    _caratErrorClear?.cancel();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minCaratCtrl.dispose();
    _maxCaratCtrl.dispose();
    _advMinLenCtrl.dispose();
    _advMaxLenCtrl.dispose();
    _advMinWidthCtrl.dispose();
    _advMaxWidthCtrl.dispose();
    _advMinDepthCtrl.dispose();
    _advMaxDepthCtrl.dispose();
    _advMinLwCtrl.dispose();
    _advMaxLwCtrl.dispose();
    _advMinCrownCtrl.dispose();
    _advMaxCrownCtrl.dispose();
    _advMinTableCtrl.dispose();
    _advMaxTableCtrl.dispose();
    _advMinPavilionCtrl.dispose();
    _advMaxPavilionCtrl.dispose();
    _advMinPriceUsdCtrl.dispose();
    _advMaxPriceUsdCtrl.dispose();
    super.dispose();
  }

  void _onCaratChanged() {
    _caratErrorDebounce?.cancel();
    _caratErrorClear?.cancel();

    final hasMin = _minCaratCtrl.text.trim().isNotEmpty;
    final hasMax = _maxCaratCtrl.text.trim().isNotEmpty;

    if (hasMin && hasMax && !_isCaratValid) {
      _caratErrorDebounce = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showCaratError = true);
      });
    } else {
      if (_showCaratError) {
        _caratErrorClear = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showCaratError = false);
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DATA FETCHING (matches React buildFilters)
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _buildFilters() {
    final params = <String, dynamic>{
      'from': 0,
      'to': 10,
      'hasImage': true,
      'hasVideo': _video,
      'count': true,
    };

    // Shape
    final shapeFilters =
        _selectedFilters.where((f) => _shapeOptions.contains(f)).toList();
    if (shapeFilters.length == 1) params['shape'] = shapeFilters[0];

    // Clarity
    final clarityFilters =
        _selectedFilters.where((f) => _clarityOptions.contains(f)).toList();
    if (clarityFilters.length == 1) params['clarity'] = clarityFilters[0];

    // Color
    final colorFilters =
        _selectedFilters.where((f) => _colorOptions.contains(f)).toList();
    if (colorFilters.length == 1) params['color'] = colorFilters[0];

    // Cut
    final cutFilters =
        _selectedFilters.where((f) => _cutOptions.contains(f)).toList();
    if (cutFilters.length == 1) params['cut'] = cutFilters[0];

    // Polish
    final polishFilters =
        _selectedFilters.where((f) => _polishOptions.contains(f)).toList();
    if (polishFilters.length == 1) params['polish'] = polishFilters[0];

    // Symmetry
    final symmetryFilters =
        _selectedFilters.where((f) => _symmetryOptions.contains(f)).toList();
    if (symmetryFilters.length == 1) params['symmetry'] = symmetryFilters[0];

    // Fluorescence
    final fluorescenceFilters = _selectedFilters
        .where((f) => _fluorescenceOptions.contains(f))
        .toList();
    if (fluorescenceFilters.length == 1)
      params['fluorescence'] = fluorescenceFilters[0];

    // Certificate
    final certFilters =
        _selectedFilters.where((f) => _certificateOptions.contains(f)).toList();
    if (certFilters.length == 1) params['certificate'] = certFilters[0];

    // Sort
    if (_sortOrder != 'none') {
      params['sortBy'] = 'finalPrice';
      params['sortOrder'] = _sortOrder == 'Low to high' ? 'asc' : 'desc';
    }

    // Price
    if (_minPriceCtrl.text.isNotEmpty)
      params['minFinalPrice'] = double.tryParse(_minPriceCtrl.text);
    if (_maxPriceCtrl.text.isNotEmpty)
      params['maxFinalPrice'] = double.tryParse(_maxPriceCtrl.text);

    // Carat
    if (_minCaratCtrl.text.isNotEmpty)
      params['minCarat'] = double.tryParse(_minCaratCtrl.text);
    if (_maxCaratCtrl.text.isNotEmpty)
      params['maxCarat'] = double.tryParse(_maxCaratCtrl.text);

    // Buyback (tri-state: true/false/null)
    if (_buyback == true) {
      params['hasBuyback'] = true;
    } else if (_buyback == false) {
      params['hasBuyback'] = false;
    }

    // Advanced filters
    final minLen = double.tryParse(_advMinLenCtrl.text);
    final maxLen = double.tryParse(_advMaxLenCtrl.text);
    final minW = double.tryParse(_advMinWidthCtrl.text);
    final maxW = double.tryParse(_advMaxWidthCtrl.text);
    final minD = double.tryParse(_advMinDepthCtrl.text);
    final maxD = double.tryParse(_advMaxDepthCtrl.text);
    final minLw = double.tryParse(_advMinLwCtrl.text);
    final maxLw = double.tryParse(_advMaxLwCtrl.text);
    final minCrown = double.tryParse(_advMinCrownCtrl.text);
    final maxCrown = double.tryParse(_advMaxCrownCtrl.text);
    final minTable = double.tryParse(_advMinTableCtrl.text);
    final maxTable = double.tryParse(_advMaxTableCtrl.text);
    final minPav = double.tryParse(_advMinPavilionCtrl.text);
    final maxPav = double.tryParse(_advMaxPavilionCtrl.text);
    final minUsd = double.tryParse(_advMinPriceUsdCtrl.text);
    final maxUsd = double.tryParse(_advMaxPriceUsdCtrl.text);

    if (minLen != null && minLen > 0) params['minLength'] = minLen;
    if (maxLen != null && maxLen > 0) params['maxLength'] = maxLen;
    if (minW != null && minW > 0) params['minWidth'] = minW;
    if (maxW != null && maxW > 0) params['maxWidth'] = maxW;
    if (minD != null && minD > 0) params['minHeight'] = minD;
    if (maxD != null && maxD > 0) params['maxHeight'] = maxD;
    if (minLw != null && minLw > 0) params['minLwRatio'] = minLw;
    if (maxLw != null && maxLw > 0) params['maxLwRatio'] = maxLw;
    if (minCrown != null && minCrown > 0) params['minCrownAngle'] = minCrown;
    if (maxCrown != null && maxCrown > 0) params['maxCrownAngle'] = maxCrown;
    if (minTable != null && minTable > 0) params['minTablePercent'] = minTable;
    if (maxTable != null && maxTable > 0) params['maxTablePercent'] = maxTable;
    if (minPav != null && minPav > 0) params['minPavilionAngle'] = minPav;
    if (maxPav != null && maxPav > 0) params['maxPavilionAngle'] = maxPav;
    if (minUsd != null && minUsd > 0) params['minPriceUsd'] = minUsd;
    if (maxUsd != null && maxUsd > 0) params['maxPriceUsd'] = maxUsd;

    return params;
  }

  Future<void> _fetchProducts({int page = 0, bool append = false}) async {
    setState(() {
      _loadingProducts = true;
      _error = '';
    });

    final api = _diamondApi();
    final filters = _buildFilters();
    filters['from'] = page * 10;
    filters['to'] = (page + 1) * 10;

    final result = await api.fetchDiamondProducts(
      from: filters['from'] as int,
      to: filters['to'] as int,
      hasImage: filters['hasImage'] as bool? ?? true,
      hasVideo: filters['hasVideo'] as bool? ?? true,
      shape: filters['shape'] as String?,
      color: filters['color'] as String?,
      clarity: filters['clarity'] as String?,
      cut: filters['cut'] as String?,
      polish: filters['polish'] as String?,
      symmetry: filters['symmetry'] as String?,
      fluorescence: filters['fluorescence'] as String?,
      certificate: filters['certificate'] as String?,
      minCarat: filters['minCarat'] as double?,
      maxCarat: filters['maxCarat'] as double?,
      minFinalPrice: filters['minFinalPrice'] as double?,
      maxFinalPrice: filters['maxFinalPrice'] as double?,
      hasBuyback: filters['hasBuyback'] as bool?,
      sortBy: filters['sortBy'] as String?,
      sortOrder: filters['sortOrder'] as String?,
      minLength: filters['minLength'] as double?,
      maxLength: filters['maxLength'] as double?,
      minWidth: filters['minWidth'] as double?,
      maxWidth: filters['maxWidth'] as double?,
      minHeight: filters['minHeight'] as double?,
      maxHeight: filters['maxHeight'] as double?,
      minLwRatio: filters['minLwRatio'] as double?,
      maxLwRatio: filters['maxLwRatio'] as double?,
      minCrownAngle: filters['minCrownAngle'] as double?,
      maxCrownAngle: filters['maxCrownAngle'] as double?,
      minTablePercent: filters['minTablePercent'] as double?,
      maxTablePercent: filters['maxTablePercent'] as double?,
      minPavilionAngle: filters['minPavilionAngle'] as double?,
      maxPavilionAngle: filters['maxPavilionAngle'] as double?,
      minPriceUsd: filters['minPriceUsd'] as double?,
      maxPriceUsd: filters['maxPriceUsd'] as double?,
    );

    if (!mounted) return;

    setState(() {
      _loadingProducts = false;
      if (result['ok'] == true) {
        final rawData = result['data'];
        List<dynamic> productsList = [];
        int total = 0;

        if (rawData is List) {
          // API returns data as a direct list: { "data": [...] }
          productsList = rawData;
          total = rawData.length;
        } else if (rawData is Map<String, dynamic>) {
          // API returns data as a map: { "data": { "products": [...], "total": N } }
          final innerData = rawData['data'];
          if (innerData is List) {
            productsList = innerData;
            total = rawData['total'] as int? ?? innerData.length;
          } else {
            productsList = rawData['products'] as List<dynamic>? ?? [];
            total = rawData['total'] as int? ?? productsList.length;
          }
        }

        final newProducts = productsList
            .map((e) => DiamondProduct.fromJson(e as Map<String, dynamic>))
            .toList();

        if (append) {
          final existingIds = _products.map((p) => p.productId).toSet();
          final deduped = newProducts
              .where((p) => !existingIds.contains(p.productId))
              .toList();
          _products = [..._products, ...deduped];
        } else {
          final seen = <String>{};
          _products = newProducts.where((p) => seen.add(p.productId)).toList();
        }

        _totalProducts = total;
        _currentPage = page;
        _hasMore = _products.length < _totalProducts;
      } else {
        if (!append) _products = [];
        _error = result['message']?.toString() ?? 'Failed to load diamonds';
      }
    });
  }

  Future<void> _fetchCart() async {
    setState(() => _loadingCart = true);
    final api = _diamondApi();
    final result = await api.fetchDiamondCart();
    if (!mounted) return;
    setState(() {
      _loadingCart = false;
      if (result['ok'] == true) {
        final raw = result['raw'] as Map<String, dynamic>? ?? {};
        final data = raw['data'];
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = (data['cartItems'] as List<dynamic>?) ??
              (data['items'] as List<dynamic>?) ??
              [];
        } else {
          items = [];
        }
        _cartItems = items
            .map((e) => DiamondCartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _selectedCartItemIds = _cartItems.map((i) => i.id).toSet();
        _allSelected = true;
      }
    });
  }

  Future<void> _addToCart(DiamondProduct product) async {
    if (_addingToCart) return;
    setState(() => _addingToCart = true);
    try {
      final api = _diamondApi();
      final result = await api.addToDiamondCart(product.productId);
      if (mounted && result['ok'] == true) {
        await _fetchCart();
        if (mounted) {
          setState(() => _step = 'cart');
        }
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _removeFromCart(String cartItemId) async {
    final api = _diamondApi();
    final result = await api.removeDiamondCartItem(cartItemId);
    if (mounted && result['ok'] == true) {
      await _fetchCart();
      if (mounted) {
        _selectedCartItemIds.remove(cartItemId);
        if (_cartItems.isEmpty) {
          setState(() => _step = 'products');
        }
      }
    }
  }

  double get _selectedTotal {
    double total = 0;
    for (final item in _cartItems) {
      if (_selectedCartItemIds.contains(item.id)) {
        total += item.unitPrice * item.quantity;
      }
    }
    return total;
  }

  List<DiamondCartItem> get _selectedCartItems =>
      _cartItems.where((i) => _selectedCartItemIds.contains(i.id)).toList();

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [_bgDark, Colors.black],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 60,
              offset: Offset(0, -24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const [0, 0.18, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Column(
                  children: [
                    _buildDragHandle(),
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildStepIndicator(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildStepContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Drag Handle ──────────────────────────────────────────────────────────

  Widget _buildDragHandle() {
    return Container(
      width: 100,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF3E3E3E),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ─── Step Indicator (3-segment bar) ───────────────────────────────────────

  Widget _buildStepIndicator() {
    int currentStep;
    switch (_step) {
      case 'filters':
      case 'products':
        currentStep = 0;
      case 'cart':
        currentStep = 1;
      case 'payment':
      case 'processing':
      case 'success':
        currentStep = 2;
      default:
        currentStep = 0;
    }

    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? (isCurrent ? _primary : _primary.withValues(alpha: 0.6))
                  : const Color(0xFF2E2E2E),
            ),
          ),
        );
      }),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final showBack = _step != 'processing' && _step != 'success';
    final showCart = _step == 'filters' || _step == 'products';

    String title;
    switch (_step) {
      case 'filters':
        title = 'Buy Diamonds';
      case 'products':
        title = 'Choose Diamonds';
      case 'cart':
        title = 'Your Cart';
      case 'payment':
        title = 'Payment';
      case 'processing':
        title = 'Processing';
      case 'success':
        title = 'Payment Successful!';
      default:
        title = 'Buy Diamonds';
    }

    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: _handleBack,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Colors.white),
                ),
              ),
            ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          if (showCart)
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: () {
                  _fetchCart();
                  setState(() => _step = 'cart');
                },
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 22, color: Colors.white),
                      if (_cartItems.isNotEmpty)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: _primary, shape: BoxShape.circle),
                            child: Text(
                              '${_cartItems.length}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleBack() {
    switch (_step) {
      case 'products':
        setState(() => _step = 'filters');
      case 'cart':
        setState(() => _step = 'products');
      case 'payment':
        setState(() => _step = 'cart');
      default:
        context.go(AppRoutes.home);
    }
  }

  // ─── Step Content Router ──────────────────────────────────────────────────

  Widget _buildStepContent() {
    switch (_step) {
      case 'filters':
        return _buildFiltersStep();
      case 'products':
        return _buildProductsStep();
      case 'cart':
        return _buildCartStep();
      case 'payment':
        return _buildPaymentStep();
      case 'processing':
        return _buildProcessingStep();
      case 'success':
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 1: FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFiltersStep() {
    return Column(
      children: [
        _buildFilterTabs(),
        const SizedBox(height: 8),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _activeFilterTab == 'main'
                    ? _buildMainFilters()
                    : _buildAdvancedFilters(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildSearchButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF1A1A1A),
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterTab('Main Filters', 'main')),
          Expanded(child: _buildFilterTab('Advanced Filter', 'advanced')),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String key) {
    final isActive = _activeFilterTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilterTab = key),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive ? _primary : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final isValid = _isCaratValid;
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isValid
              ? const LinearGradient(
                  colors: [Color(0xFF0084FF), _primary, Color(0xFF005BB5)])
              : null,
          color: isValid ? null : const Color(0xFF2A2A2A),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: (_loadingProducts || !isValid)
                ? null
                : () {
                    setState(() => _step = 'products');
                    _fetchProducts(page: 0);
                  },
            child: Center(
              child: _loadingProducts
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Search Diamonds',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isValid ? Colors.white : const Color(0xFF6E6E6E),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Main Filters ─────────────────────────────────────────────────────────

  Widget _buildMainFilters() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          _buildSectionLabel('Price'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _buildFilterInput(
                      hint: 'Min', controller: _minPriceCtrl)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildFilterInput(
                      hint: 'Max', controller: _maxPriceCtrl)),
            ],
          ),
          const SizedBox(height: 12),

          // Sort
          _buildSectionLabel('Sort'),
          const SizedBox(height: 6),
          _buildSortDropdown(),
          const SizedBox(height: 12),

          // Video toggle
          _buildToggleRow('Video', _video, (v) => setState(() => _video = v)),
          const SizedBox(height: 8),

          // Buyback toggle (tri-state)
          _buildBuybackToggle(),
          const SizedBox(height: 12),

          // Carat (required, with validation)
          _buildSectionLabel('Carat', required_: true),
          const SizedBox(height: 4),
          const Text(
            'Choose the min-max carats for diamonds',
            style: TextStyle(fontSize: 10, color: Color(0xFF6E6E6E)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildFilterInput(
                  hint: 'Min',
                  controller: _minCaratCtrl,
                  onChanged: (_) => _onCaratChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterInput(
                  hint: 'Max',
                  controller: _maxCaratCtrl,
                  onChanged: (_) => _onCaratChanged(),
                ),
              ),
            ],
          ),
          if (_showCaratError) ...[
            const SizedBox(height: 4),
            const Text(
              'Please enter a valid carat range (min > 0, max >= min).',
              style: TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 12),

          // Certificate (multi-select chips)
          _buildFilterChipSection(
            label: 'Certificate',
            options: _certificateOptions,
          ),
          const SizedBox(height: 12),

          // Shape (multi-select chips)
          _buildFilterChipSection(
            label: 'Shape',
            options: _shapeOptions,
          ),
          const SizedBox(height: 12),

          // Clarity (multi-select chips)
          _buildFilterChipSection(
            label: 'Clarity',
            options: _clarityOptions,
          ),
          const SizedBox(height: 12),

          // Color (multi-select chips)
          _buildFilterChipSection(
            label: 'Color',
            options: _colorOptions,
          ),
          const SizedBox(height: 12),

          // Cut (multi-select chips)
          _buildFilterChipSection(
            label: 'Cut',
            options: _cutOptions,
          ),
          const SizedBox(height: 12),

          // Polish (multi-select chips)
          _buildFilterChipSection(
            label: 'Polish',
            options: _polishOptions,
          ),
          const SizedBox(height: 12),

          // Symmetry (multi-select chips)
          _buildFilterChipSection(
            label: 'Symmetry',
            options: _symmetryOptions,
          ),
          const SizedBox(height: 12),

          // Fluorescence (multi-select chips)
          _buildFilterChipSection(
            label: 'Fluorescence',
            options: _fluorescenceOptions,
          ),
        ],
      ),
    );
  }

  // ─── Advanced Filters ─────────────────────────────────────────────────────

  Widget _buildAdvancedFilters() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedMinMaxRow(
              'Length (mm)', _advMinLenCtrl, _advMaxLenCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow(
              'Width (mm)', _advMinWidthCtrl, _advMaxWidthCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow(
              'Depth (mm)', _advMinDepthCtrl, _advMaxDepthCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow('L/W (Ratio)', _advMinLwCtrl, _advMaxLwCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow(
              'Crown (deg)', _advMinCrownCtrl, _advMaxCrownCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow(
              'Table (%)', _advMinTableCtrl, _advMaxTableCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow(
              'Pavilion (deg)', _advMinPavilionCtrl, _advMaxPavilionCtrl),
          const SizedBox(height: 12),
          _buildAdvancedMinMaxRow(
              'Price (USD)', _advMinPriceUsdCtrl, _advMaxPriceUsdCtrl),
        ],
      ),
    );
  }

  Widget _buildAdvancedMinMaxRow(String label, TextEditingController minCtrl,
      TextEditingController maxCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
                child: _buildFilterInput(hint: 'Min', controller: minCtrl)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildFilterInput(hint: 'Max', controller: maxCtrl)),
          ],
        ),
      ],
    );
  }

  // ─── Filter Card Container ────────────────────────────────────────────────

  Widget _buildFilterCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF141414),
      ),
      child: child,
    );
  }

  // ─── Filter Input ─────────────────────────────────────────────────────────

  Widget _buildFilterInput({
    required String hint,
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF1E1E1E),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5E5E5E)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Section Label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, {bool required_ = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary),
        ),
        if (required_) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(fontSize: 12, color: Colors.redAccent)),
        ],
      ],
    );
  }

  // ─── Sort Dropdown ────────────────────────────────────────────────────────

  Widget _buildSortDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        color: const Color(0xFF1E1E1E),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortOrder,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: _textSecondary, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.white),
          items: ['Low to high', 'High to low'].map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _sortOrder = v);
          },
        ),
      ),
    );
  }

  // ─── Toggle Row ───────────────────────────────────────────────────────────

  Widget _buildToggleRow(
      String label, bool yesSelected, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: _textSecondary)),
        const Spacer(),
        _buildTogglePill(
            text: 'Yes', isActive: yesSelected, onTap: () => onChanged(true)),
        const SizedBox(width: 6),
        _buildTogglePill(
            text: 'No', isActive: !yesSelected, onTap: () => onChanged(false)),
      ],
    );
  }

  // ─── Buyback Toggle (tri-state: null/true/false) ─────────────────────────

  Widget _buildBuybackToggle() {
    return Row(
      children: [
        const Text('Buyback',
            style: TextStyle(fontSize: 12, color: _textSecondary)),
        const Spacer(),
        _buildTogglePill(
          text: 'Yes',
          isActive: _buyback == true,
          onTap: () =>
              setState(() => _buyback = _buyback == true ? null : true),
        ),
        const SizedBox(width: 6),
        _buildTogglePill(
          text: 'No',
          isActive: _buyback == false,
          onTap: () =>
              setState(() => _buyback = _buyback == false ? null : false),
        ),
      ],
    );
  }

  Widget _buildTogglePill(
      {required String text,
      required bool isActive,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? _primary : const Color(0xFF1E1E1E),
          border: Border.all(color: isActive ? _primary : _cardBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  // ─── Filter Chip Section (multi-select) ──────────────────────────────────

  Widget _buildFilterChipSection({
    required String label,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((option) {
            final isActive = _hasFilter(option);
            return GestureDetector(
              onTap: () => _toggleFilter(option),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isActive
                      ? (label == 'Cut' ? const Color(0xFF2563EB) : _primary)
                      : const Color(0xFF1E1E1E),
                  border: Border.all(
                    color: isActive
                        ? (label == 'Cut' ? const Color(0xFF2563EB) : _primary)
                        : _cardBorder,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 2: PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProductsStep() {
    if (_loadingProducts && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_error.isNotEmpty && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: Colors.redAccent.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(_error,
                style: const TextStyle(fontSize: 13, color: _textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _fetchProducts(page: 0),
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 13,
                      color: _primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond_outlined,
                size: 48, color: Color(0xFF3E3E3E)),
            const SizedBox(height: 12),
            const Text('No diamonds found',
                style: TextStyle(fontSize: 14, color: _textSecondary)),
            const SizedBox(height: 4),
            const Text('Try adjusting filters',
                style: TextStyle(fontSize: 12, color: Color(0xFF6E6E6E))),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _step = 'filters'),
              child: const Text(
                'Edit Filters',
                style: TextStyle(
                    fontSize: 13, color: _primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          '$_totalProducts diamonds found',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.52,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final inCartItem = _cartItems
                  .where((c) => c.productId == product.productId)
                  .firstOrNull;
              final quantity = inCartItem?.quantity ?? 0;

              return DiamondCard(
                product: product,
                showVideo: _video,
                quantity: quantity,
                onAddToCart: () => _addToCart(product),
                onRemove: () {
                  if (inCartItem != null) _removeFromCart(inCartItem.id);
                },
                onIncrement: () => _addToCart(product),
              );
            },
          ),
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _primary),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _loadingProducts
                        ? null
                        : () => _fetchProducts(
                            page: _currentPage + 1, append: true),
                    child: Center(
                      child: _loadingProducts
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _primary),
                            )
                          : const Text(
                              'Load More',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primary),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 3: CART
  // ═══════════════════════════════════════════════════════════════════════════

  static const Duration _reservationDuration = Duration(minutes: 30);

  _ReservationInfo _getEarliestReservation() {
    DateTime? earliest;
    for (final item in _cartItems) {
      final created = item.createdAt;
      if (created == null) continue;
      final expiry = created.add(_reservationDuration);
      if (earliest == null ||
          expiry.isBefore(earliest.add(_reservationDuration))) {
        earliest = created;
      }
    }
    if (earliest == null) {
      return const _ReservationInfo(
          display: '30:00', progress: 1.0, expired: false);
    }
    final expiry = earliest.add(_reservationDuration);
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      return const _ReservationInfo(
          display: '00:00', progress: 0.0, expired: true);
    }
    final totalMs = _reservationDuration.inMilliseconds;
    final remainingMs = remaining.inMilliseconds;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return _ReservationInfo(
      display:
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      progress: remainingMs / totalMs,
      expired: false,
    );
  }

  bool _isAnyItemExpired() {
    for (final item in _cartItems) {
      final created = item.createdAt;
      if (created == null) continue;
      if (DateTime.now().isAfter(created.add(_reservationDuration)))
        return true;
    }
    return false;
  }

  Widget _buildCartStep() {
    if (_loadingCart) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: _textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Your cart is empty',
                style: TextStyle(fontSize: 14, color: _textSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _step = 'products'),
              child: const Text(
                'Browse Diamonds',
                style: TextStyle(
                    fontSize: 13, color: _primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final reservation = _getEarliestReservation();
    final anyExpired = _isAnyItemExpired();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reservation countdown banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: reservation.expired
                          ? [const Color(0xFF3B1A1A), const Color(0xFF1A0A0A)]
                          : [const Color(0xFF0A2A3B), const Color(0xFF0A1520)],
                    ),
                    border: Border.all(
                      color: reservation.expired
                          ? const Color(0xFF5C2020)
                          : const Color(0xFF0067B8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.expired
                                  ? 'Reservation Expired'
                                  : 'Complete your payment',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: reservation.expired
                                    ? const Color(0xFFFF6B6B)
                                    : _accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reservation.expired
                                  ? 'Your reservation has expired. Please reserve the product again.'
                                  : 'Your selected product has been reserved exclusively for you.',
                              style: TextStyle(
                                fontSize: 8,
                                height: 1.4,
                                color: reservation.expired
                                    ? const Color(0xFFFF9E9E)
                                    : _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!reservation.expired) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CustomPaint(
                            painter: _ReservationTimerPainter(
                              progress: reservation.progress,
                              color: _accent,
                            ),
                            child: Center(
                              child: Text(
                                reservation.display,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Select All / Deselect All with count
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _allSelected = !_allSelected;
                          if (_allSelected) {
                            _selectedCartItemIds =
                                _cartItems.map((i) => i.id).toSet();
                          } else {
                            _selectedCartItemIds.clear();
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _allSelected
                                    ? _primary
                                    : const Color(0xFF515151),
                                width: 2,
                              ),
                              color:
                                  _allSelected ? _primary : Colors.transparent,
                            ),
                            child: _allSelected
                                ? const Icon(Icons.check,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _allSelected ? 'Deselect All' : 'Select All',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedCartItemIds.length} of ${_cartItems.length} selected',
                      style:
                          const TextStyle(fontSize: 10, color: _textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cart item cards
                ...List.generate(_cartItems.length, (index) {
                  final item = _cartItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCartItemCard(item),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Total Payable
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder),
            color: const Color(0xFF26313B),
          ),
          child: Row(
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary),
              ),
              const Spacer(),
              Text(
                '₹${_formatPrice(_selectedTotal)}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Proceed to Pay or Reserve Again button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: anyExpired || _selectedCartItemIds.isEmpty
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF006FC7), Color(0xFF00457C)]),
              color: anyExpired || _selectedCartItemIds.isEmpty
                  ? const Color(0xFF2A2A2A)
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: anyExpired
                    ? () => setState(() => _step = 'products')
                    : _selectedCartItemIds.isEmpty
                        ? null
                        : () => setState(() => _step = 'payment'),
                child: Center(
                  child: Text(
                    anyExpired
                        ? 'Reserve Again'
                        : 'Proceed to Pay${_selectedCartItemIds.isNotEmpty ? ' (₹${_formatPrice(_selectedTotal)})' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: anyExpired || _selectedCartItemIds.isEmpty
                          ? _textSecondary
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(DiamondCartItem item) {
    final isSelected = _selectedCartItemIds.contains(item.id);
    final created = item.createdAt;
    final isExpired = created != null &&
        DateTime.now().isAfter(created.add(_reservationDuration));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? (isExpired ? const Color(0xFF5C2020) : _primary)
              : _cardBorder,
        ),
        color: const Color(0xFF26313B),
        boxShadow: isSelected && !isExpired
            ? [
                BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    spreadRadius: 4)
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCartItemIds.remove(item.id);
                    } else {
                      _selectedCartItemIds.add(item.id);
                    }
                    _allSelected =
                        _selectedCartItemIds.length == _cartItems.length;
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? _primary : const Color(0xFF515151),
                      width: 2,
                    ),
                    color: isSelected ? _primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // Thumbnail
              DiamondCartThumb(item: item, placeholderColor: _accent),
              const SizedBox(width: 10),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName.isNotEmpty
                          ? item.productName
                          : 'Diamond',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF7E7E7E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accent),
                    ),
                  ],
                ),
              ),

              // Remove button
              GestureDetector(
                onTap: () => _removeFromCart(item.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(fontSize: 10, color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),

          // Per-item reservation timer
          if (created != null) ...[
            const SizedBox(height: 8),
            _CartItemTimer(
              createdAt: created,
              onExpired: () => _removeFromCart(item.id),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 4: PAYMENT (uses EmbeddedPaymentGateway)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentStep() {
    final selectedItems = _selectedCartItems;

    return Column(
      children: [
        // Order summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            color: const Color(0xFF141414),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 20, color: _accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: _success),
                        SizedBox(width: 4),
                        Text('Secure',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _success)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...selectedItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName.isNotEmpty
                              ? item.productName
                              : 'Diamond',
                          style: const TextStyle(
                              fontSize: 11, color: _textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '×${item.quantity}',
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${item.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: _cardBorder, height: 16),
              Row(
                children: [
                  const Text('Total Payable',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const Spacer(),
                  Text(
                    '₹${_formatPrice(_selectedTotal)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pay Now card (matching gold/silver EmbeddedPaymentGateway style)
        _DiamondPayNowCard(
          amount: _selectedTotal,
          items: _selectedCartItems
              .map((e) => {
                    'id': e.id,
                    'productId': e.productId,
                    'amount': e.unitPrice,
                  })
              .toList(),
          onPaymentStarted: () {
            if (mounted) setState(() => _step = 'processing');
          },
          onPaymentError: (msg) {
            if (mounted) setState(() => _step = 'cart');
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 5: PROCESSING (concentric rings animation)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProcessingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: AnimatedBuilder(
              animation: _processingAnimController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConcentricRingsPainter(
                    progress: _processingAnimController.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Payment Processing',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Securing Your Diamond...',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 6: SUCCESS (inline, matching React)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSuccessStep() {
    // Read from localStorage context
    Map<String, dynamic> paymentCtx = {};
    try {
      final raw = LocalStorageService.getDiamondPaymentContext();
      if (raw != null && raw.isNotEmpty) {
        paymentCtx = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}

    final paidAmount = paymentCtx['amount'] ?? _selectedTotal;
    final orderRef =
        paymentCtx['merchantOrderRef'] ?? paymentCtx['sabbpeOrderId'] ?? 'N/A';
    final diamondName =
        _cartItems.isNotEmpty ? _cartItems.first.productName : 'Diamond';

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glow check circle (matching reference: blue gradient + boxShadow)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0167B8), Colors.black],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.5),
                    blurRadius: 100,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your diamond has been ordered successfully',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),

            // Order details card
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3E3E3E)),
                color: const Color(0xFF26313B),
              ),
              child: Column(
                children: [
                  _buildOrderDetailRow('Amount paid', '₹$paidAmount'),
                  const SizedBox(height: 12),
                  _buildOrderDetailRow('Diamond', diamondName),
                  const SizedBox(height: 12),
                  _buildOrderDetailRow('Order Ref', '#$orderRef'),
                  const SizedBox(height: 12),
                  _buildOrderDetailRow('Status', 'Completed', isStatus: true),
                ],
              ),
            ),

            // Action buttons
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF3E3E3E)),
                        color: const Color(0xFF1B1913),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: const Center(
                            child: Text(
                              'Go Home',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0073CE), Color(0xFF004175)]),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            setState(() {
                              _step = 'filters';
                              _selectedFilters.clear();
                              _minPriceCtrl.clear();
                              _maxPriceCtrl.clear();
                              _minCaratCtrl.clear();
                              _maxCaratCtrl.clear();
                              _buyback = null;
                              _video = true;
                            });
                            _fetchCart();
                          },
                          child: const Center(
                            child: Text(
                              'Buy More',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value,
      {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _success),
                ),
              )
            : Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatPrice(double price) {
    final intValue = price.toInt();
    final buf = StringBuffer();
    final s = intValue.toString();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      count++;
      buf.write(s[i]);
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      } else if (count == 2 && i != 0 && s.length > 3) {
        final prev = i > 0 ? s[i - 1] : '';
        if (prev.isNotEmpty && prev != ',') {
          buf.write(',');
          count = 0;
        }
      }
    }
    return buf.toString().split('').reversed.join();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONCENTRIC RINGS PAINTER (matches React ConcentricRings component)
// ═══════════════════════════════════════════════════════════════════════════════

class _ConcentricRingsPainter extends CustomPainter {
  final double progress;

  _ConcentricRingsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final rings = [
      _RingConfig(
          radiusFraction: 1.0,
          color: const Color(0xFF3AC7FF),
          strokeWidth: 2,
          speed: 1.0),
      _RingConfig(
          radiusFraction: 0.82,
          color: const Color(0xFF0084FF),
          strokeWidth: 2,
          speed: -0.8),
      _RingConfig(
          radiusFraction: 0.64,
          color: const Color(0xFF3AC7FF),
          strokeWidth: 1.5,
          speed: 1.2),
      _RingConfig(
          radiusFraction: 0.46,
          color: const Color(0xFF0084FF),
          strokeWidth: 1.5,
          speed: -1.0),
      _RingConfig(
          radiusFraction: 0.28,
          color: const Color(0xFF3AC7FF),
          strokeWidth: 1,
          speed: 0.6),
    ];

    for (final ring in rings) {
      final radius = maxRadius * ring.radiusFraction;
      final paint = Paint()
        ..color = ring.color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth;

      // Draw full circle with low opacity
      canvas.drawCircle(center, radius, paint);

      // Draw rotating arc
      final arcPaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = 2 * pi * progress * ring.speed;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        pi / 2,
        false,
        arcPaint,
      );
    }

    // Center dot
    final dotPaint = Paint()
      ..color = const Color(0xFF3AC7FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(_ConcentricRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RingConfig {
  final double radiusFraction;
  final Color color;
  final double strokeWidth;
  final double speed;

  const _RingConfig({
    required this.radiusFraction,
    required this.color,
    required this.strokeWidth,
    required this.speed,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DIAMOND PAY NOW CARD (matching gold/silver EmbeddedPaymentGateway style)
// ═══════════════════════════════════════════════════════════════════════════════

class _DiamondPayNowCard extends ConsumerStatefulWidget {
  final double amount;
  final List<Map<String, dynamic>> items;
  final VoidCallback onPaymentStarted;
  final void Function(String error) onPaymentError;

  const _DiamondPayNowCard({
    required this.amount,
    required this.items,
    required this.onPaymentStarted,
    required this.onPaymentError,
  });

  @override
  ConsumerState<_DiamondPayNowCard> createState() => _DiamondPayNowCardState();
}

class _DiamondPayNowCardState extends ConsumerState<_DiamondPayNowCard> {
  bool _loading = false;
  String _error = '';

  static const Color _accent = Color(0xFF0084FF);
  static const Color _accentDark = Color(0xFF004D96);

  String get _clientId => LocalStorageService.getDiamondClientId() ?? '';

  CashfreeApi _cashfreeApi() {
    final dio = ref.read(augmontDioProvider);
    return CashfreeApi(dio);
  }

  Future<void> _startPayment() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (_clientId.isEmpty) throw Exception('Please login again');

      final api = _cashfreeApi();
      final response = await api.createDiamondPayment(
        clientId: _clientId,
        totalAmount: widget.amount,
        items: widget.items,
      );

      if (response.paymentSessionId.isEmpty) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Payment session ID is missing');
      }

      await LocalStorageService.setDiamondPaymentContext(jsonEncode({
        'type': 'diamond',
        'amount': widget.amount,
        'items': widget.items,
        'sabbpeOrderId': response.sabbpeOrderId,
        'merchantOrderRef': response.merchantOrderId.isNotEmpty
            ? response.merchantOrderId
            : response.sabbpeOrderId,
      }));

      if (!mounted) return;

      widget.onPaymentStarted();

      context.go(AppRoutes.paymentGateway, extra: {
        'paymentSessionId': response.paymentSessionId,
        'orderId': response.merchantOrderId.isNotEmpty
            ? response.merchantOrderId
            : response.sabbpeOrderId,
        'amount': widget.amount,
      });
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = msg;
        _loading = false;
      });
      widget.onPaymentError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            color: const Color(0xFF1A2332),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient:
                          const LinearGradient(colors: [_accent, _accentDark]),
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withValues(alpha: 0.25),
                            blurRadius: 22)
                      ],
                    ),
                    child: const Icon(Icons.credit_card,
                        size: 21, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Pay Now',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                  color: const Color(0xFF101820),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount payable',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF7E7E7E))),
                    Text(
                      '₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF2A1111),
                    border: Border.all(color: const Color(0xFF6B2A2A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF3A1515),
                        ),
                        child: const Icon(Icons.close,
                            size: 17, color: Color(0xFFFF6B6B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment could not start',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            Text(_error,
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFFD8B8B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient:
                        const LinearGradient(colors: [_accent, _accentDark]),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: _loading ? null : _startPayment,
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 17, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Pay Now',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            color: const Color(0xFF1A2332),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield, size: 12, color: Color(0xFF15EE01)),
              SizedBox(width: 6),
              Text('Secure checkout powered by Cashfree',
                  style: TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RESERVATION COUNTDOWN (banner + per-item)
// ═══════════════════════════════════════════════════════════════════════════════

class _ReservationInfo {
  final String display;
  final double progress;
  final bool expired;

  const _ReservationInfo({
    required this.display,
    required this.progress,
    required this.expired,
  });
}

class _ReservationTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ReservationTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ReservationTimerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CART ITEM TIMER (per-item countdown matching React CartItemTimer)
// ═══════════════════════════════════════════════════════════════════════════════

class _CartItemTimer extends StatefulWidget {
  final DateTime createdAt;
  final VoidCallback? onExpired;

  const _CartItemTimer({required this.createdAt, this.onExpired});

  @override
  State<_CartItemTimer> createState() => _CartItemTimerState();
}

class _CartItemTimerState extends State<_CartItemTimer> {
  late Timer _timer;
  late Duration _remaining;
  bool _expired = false;
  static const Duration _duration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  void _calculateRemaining() {
    final expiry = widget.createdAt.add(_duration);
    final now = DateTime.now();
    final diff = expiry.difference(now);

    if (diff.isNegative) {
      if (!_expired) {
        _expired = true;
        widget.onExpired?.call();
        _timer.cancel();
      }
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final progress = _remaining.inSeconds / _duration.inSeconds;
    final isActive = !_expired;

    final color = isActive ? const Color(0xFF3AC7FF) : const Color(0xFFFF6B6B);
    final bgColor = isActive
        ? const Color(0xFF0084FF).withValues(alpha: 0.1)
        : const Color(0xFF5C2020).withValues(alpha: 0.3);
    final borderColor = isActive
        ? const Color(0xFF0084FF).withValues(alpha: 0.3)
        : const Color(0xFF5C2020);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (isActive) ...[
            SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter:
                    _ReservationTimerPainter(progress: progress, color: color),
                child: Center(
                  child: Text(
                    '$minutes:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reserved for you',
              style: TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
            ),
          ] else ...[
            Text(
              'Reservation expired',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              '\u00B7 Reserve again',
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
