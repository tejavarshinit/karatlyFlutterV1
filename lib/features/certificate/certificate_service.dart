import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api/augmont_api.dart';
import '../../core/api/diamond_api.dart';
import '../../core/storage/local_storage.dart';
import '../../core/api/config.dart';
import '../../core/models/augmont_model.dart';
import '../../core/models/gold_rate_model.dart';

// ── Shared Models ──

class CertificateCustomerInfo {
  final String name;
  final String customerId;
  final String mobileNumber;
  final String email;
  final String panMasked;
  const CertificateCustomerInfo({this.name = '', this.customerId = '', this.mobileNumber = '', this.email = '', this.panMasked = ''});
}

class CertificatePortfolioSummary {
  final double totalGoldPortfolioGrams;
  final double totalGoldPortfolioValue;
  final double totalDigitalGoldRedeemSold;
  final double currentGoldRate;
  const CertificatePortfolioSummary({this.totalGoldPortfolioGrams = 0, this.totalGoldPortfolioValue = 0, this.totalDigitalGoldRedeemSold = 0, this.currentGoldRate = 0});
}

class CertificateLatestPurchase {
  final String transactionId;
  final String purchaseDate;
  final String purchaseTime;
  final double quantity;
  final double rate;
  final double amount;
  final double gst;
  final String paymentMethod;
  final String paymentStatus;
  const CertificateLatestPurchase({this.transactionId = '', this.purchaseDate = '', this.purchaseTime = '', this.quantity = 0, this.rate = 0, this.amount = 0, this.gst = 0, this.paymentMethod = '', this.paymentStatus = ''});
}

class CertificateHistoryItem {
  final String date;
  final String transactionId;
  final double quantity;
  final double rate;
  final double amount;
  final String status;
  const CertificateHistoryItem({this.date = '', this.transactionId = '', this.quantity = 0, this.rate = 0, this.amount = 0, this.status = ''});
}

class CertificateHoldingSummary {
  final double totalGoldPortfolio;
  final double totalDigitalGoldRedeemSold;
  final double availableForRedemption;
  final String vaultStorage;
  final String goldPurity;
  final String storagePartner;
  final String insuranceCoverage;
  const CertificateHoldingSummary({this.totalGoldPortfolio = 0, this.totalDigitalGoldRedeemSold = 0, this.availableForRedemption = 0, this.vaultStorage = '', this.goldPurity = '', this.storagePartner = '', this.insuranceCoverage = ''});
}

class CertificateData {
  final String certificateNumber;
  final String issueDate;
  final String certificateType;
  final String verificationUrl;
  final String verificationHash;
  final CertificateCustomerInfo customer;
  final CertificatePortfolioSummary portfolio;
  final CertificateLatestPurchase latestPurchase;
  final List<CertificateHistoryItem> purchaseHistory;
  final CertificateHoldingSummary holdingSummary;
  final String certificateNote;
  const CertificateData({this.certificateNumber = '', this.issueDate = '', this.certificateType = '', this.verificationUrl = '', this.verificationHash = '', this.customer = const CertificateCustomerInfo(), this.portfolio = const CertificatePortfolioSummary(), this.latestPurchase = const CertificateLatestPurchase(), this.purchaseHistory = const [], this.holdingSummary = const CertificateHoldingSummary(), this.certificateNote = ''});
}

// ── Helpers ──

String _fmtDate(String value) {
  try {
    final dt = DateTime.parse(value);
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) { return value; }
}

String _fmtTime(String value) {
  try {
    final dt = DateTime.parse(value);
    final h = dt.hour, m = dt.minute.toString().padLeft(2,'0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $amPm';
  } catch (_) { return value; }
}

double _safeNum(dynamic v) {
  if (v == null) return 0;
  final n = double.tryParse(v.toString());
  return (n != null && n.isFinite) ? n : 0;
}

String _str(dynamic v) => v?.toString() ?? '';

String _maskPan(String pan) {
  final p = pan.trim().toUpperCase();
  if (p.length < 10) return p;
  return '${p.substring(0, 2)}****${p.substring(p.length - 3)}';
}

String _buildUniqueId() {
  final p = LocalStorageService.getUserProfile() ?? <String, dynamic>{};
  final m = (p['mobileNumber'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
  final m10 = m.length >= 10 ? m.substring(m.length - 10) : m;
  final dob = (p['dateOfBirth'] ?? '').toString();
  final uid = (p['uniqueId'] ?? p['augmontUniqueId'] ?? '').toString().trim();
  return uid.isNotEmpty ? uid : '$m10-$dob';
}

String _verHash(String cert) {
  final s = cert.length > 20 ? cert.substring(cert.length - 20) : cert;
  final b = StringBuffer();
  for (var i = 0; i < s.length; i += 4) {
    if (i > 0) b.write(' ');
    b.write(s.substring(i, (i + 4).clamp(0, s.length)));
  }
  return b.toString().trim();
}

// ── Gold Certificate ──

Future<Map<String, dynamic>> getCertificate({String? uniqueId, String? certificateNumber}) async {
  final uid = (uniqueId ?? _buildUniqueId()).trim();
  if (uid.isEmpty) return {'ok': false, 'message': 'Unable to resolve customer unique id.'};

  final dio = DioProvider.createDio();
  final api = AugmontApi(dio);
  try {
    final results = await Future.wait([
      api.fetchAugmontUserInfo(uniqueId: uid),
      api.fetchAugmontPassbook(uid),
      api.fetchAugmontBuyOrders(uniqueId: uid),
      api.fetchInvestmentSummary(uniqueId: uid, metalType: 'gold'),
      api.fetchLiveGoldRateSnapshot(),
    ]);

    final userInfoRes = results[0] as Map<String, dynamic>;
    final passbookRes = results[1] as Map<String, dynamic>;
    final buyOrdersRes = results[2] as Map<String, dynamic>;
    final investRes = results[3] as Map<String, dynamic>;
    final rateRes = results[4] as Map<String, dynamic>;

    if (userInfoRes['ok'] != true || passbookRes['ok'] != true || rateRes['ok'] != true) {
      return {'ok': false, 'message': 'Failed to load certificate data'};
    }

    final userInfo = userInfoRes['userInfo'] as Map<String, dynamic>? ?? {};
    final passbook = passbookRes['passbook'] as Map<String, dynamic>? ?? {};
    final rawSnapshot = rateRes['snapshot'];
    final rateObj = rawSnapshot is GoldRate ? rawSnapshot : null;
    final buyOrders = (buyOrdersRes['orders'] as List?)?.cast<AugmontOrder>() ?? <AugmontOrder>[];

    // Deep-nested extraction like React's normalizeAugmontUserInfo
    final payload = userInfo['payload'] as Map<String, dynamic>? ?? userInfo;
    final result = payload['result'] as Map<String, dynamic>? ?? payload;
    final resultData = result['data'] as Map<String, dynamic>? ?? result;
    final userInfoOuter = resultData['userInfo'] as Map<String, dynamic>? ?? resultData;
    final prof = userInfoOuter['profile'] as Map<String, dynamic>? ?? userInfoOuter;
    final source = {...resultData, ...userInfoOuter, ...prof};

    final extractedName = _str(prof['fullName'] ?? prof['userName'] ?? prof['name'] ?? source['fullName'] ?? source['userName'] ?? source['name'] ?? '');
    final extractedEmail = _str(prof['email'] ?? prof['userEmail'] ?? prof['emailId'] ?? source['email'] ?? source['userEmail'] ?? source['emailId'] ?? '');
    final extractedMobile = _str(prof['mobileNumber'] ?? prof['mobile'] ?? prof['mobileNo'] ?? source['mobileNumber'] ?? source['mobile'] ?? source['mobileNo'] ?? '');
    final storedPan = LocalStorageService.getUserPan() ?? '';
    final panRaw = storedPan.isNotEmpty ? storedPan : _str(prof['pan'] ?? prof['panNumber'] ?? source['pan'] ?? source['panNumber'] ?? '');
    final extractedCustomerId = _str(prof['uniqueId'] ?? source['uniqueId'] ?? resultData['uniqueId'] ?? resultData['customerUniqueId'] ?? uid);

    // Final fallback to localStorage profile
    final lsProfile = LocalStorageService.getUserProfile() ?? <String, dynamic>{};
    final finalName = extractedName.isNotEmpty ? extractedName : _str(lsProfile['fullName'] ?? lsProfile['name'] ?? '');
    final finalEmail = extractedEmail.isNotEmpty ? extractedEmail : _str(lsProfile['email'] ?? '');
    final finalMobile = extractedMobile.isNotEmpty ? extractedMobile : _str(lsProfile['mobileNumber'] ?? '');

    final invData = investRes['data'] as Map<String, dynamic>? ?? investRes;
    final holdingWM = _safeNum(invData['currentHoldingWithMultiplier']);
    final totalSellGrams = _safeNum(invData['totalSellGrams']);
    final goldBalance = _safeNum(passbook['goldGrms'] ?? passbook['goldBalance'] ?? passbook['gold'] ?? passbook['balance']);
    final buyPrice = rateObj?.buyPrice ?? 0;
    final portfolioValue = holdingWM * buyPrice;

    buyOrders.sort((a, b) => (DateTime.tryParse(b.date) ?? DateTime(2000)).compareTo(DateTime.tryParse(a.date) ?? DateTime(2000)));

    AugmontOrder? latest = buyOrders.isNotEmpty ? buyOrders.first : null;
    final latestDateStr = latest?.date.isNotEmpty == true ? latest!.date : DateTime.now().toIso8601String();

    final lp = CertificateLatestPurchase(
      transactionId: latest?.orderReference ?? '',
      purchaseDate: _fmtDate(latestDateStr), purchaseTime: _fmtTime(latestDateStr),
      quantity: latest?.gold ?? 0, rate: latest?.rate ?? 0, amount: latest?.amount ?? 0,
      gst: _safeNum(latest?.taxAmt) != 0 ? _safeNum(latest!.taxAmt) : ((latest?.amount ?? 0) * 0.03),
      paymentMethod: '', paymentStatus: latest?.status ?? 'Success',
    );

    final history = buyOrders.take(5).map((o) => CertificateHistoryItem(
      date: _fmtDate(o.date), transactionId: o.orderReference,
      quantity: o.gold, rate: o.rate, amount: o.amount, status: o.status,
    )).toList();

    final certNum = (certificateNumber ?? (lp.transactionId.isNotEmpty ? lp.transactionId : null) ?? uid).trim();
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    final cert = CertificateData(
      certificateNumber: certNum.isNotEmpty ? certNum : uid,
      issueDate: '${now.day} ${months[now.month - 1]} ${now.year}',
      certificateType: 'Overall Holding Certificate',
      verificationUrl: 'https://karatly.com/verify',
      verificationHash: _verHash(certNum.isNotEmpty ? certNum : uid),
      customer: CertificateCustomerInfo(
        name: extractedName,
        customerId: extractedCustomerId,
        mobileNumber: extractedMobile,
        email: extractedEmail,
        panMasked: _maskPan(panRaw),
      ),
      portfolio: CertificatePortfolioSummary(
        totalGoldPortfolioGrams: goldBalance,
        totalGoldPortfolioValue: portfolioValue,
        totalDigitalGoldRedeemSold: totalSellGrams,
        currentGoldRate: buyPrice,
      ),
      latestPurchase: lp,
      purchaseHistory: history,
      holdingSummary: CertificateHoldingSummary(
        totalGoldPortfolio: goldBalance,
        totalDigitalGoldRedeemSold: totalSellGrams,
        availableForRedemption: goldBalance,
        vaultStorage: 'Secured & Insured', goldPurity: '24K (999.9 Fine Gold)',
        storagePartner: 'Augmont Vaults', insuranceCoverage: '100% Insured',
      ),
      certificateNote: "This certificate confirms that the above-mentioned digital gold is owned by the customer and is held in secure and insured vaults by Augmont. The gold is mapped to the customer's account and can be redeemed or sold as per the applicable terms and conditions of Karatly and Augmont.",
    );
    return {'ok': true, 'certificate': cert};
  } catch (e) {
    return {'ok': false, 'message': 'Failed to load certificate details.'};
  }
}

// ── Silver Certificate ──

Future<Map<String, dynamic>> getSilverCertificate({String? uniqueId, String? certificateNumber}) async {
  final uid = (uniqueId ?? _buildUniqueId()).trim();
  if (uid.isEmpty) return {'ok': false, 'message': 'Unable to resolve customer unique id.'};

  final dio = DioProvider.createDio();
  final api = AugmontApi(dio);
  try {
    final results = await Future.wait([
      api.fetchAugmontUserInfo(uniqueId: uid),
      api.fetchAugmontPassbook(uid),
      api.fetchAugmontBuyOrders(uniqueId: uid),
      api.fetchInvestmentSummary(uniqueId: uid, metalType: 'silver'),
      api.fetchLiveGoldRateSnapshot(),
    ]);

    final userInfoRes = results[0] as Map<String, dynamic>;
    final passbookRes = results[1] as Map<String, dynamic>;
    final buyOrdersRes = results[2] as Map<String, dynamic>;
    final investRes = results[3] as Map<String, dynamic>;
    final rateRes = results[4] as Map<String, dynamic>;

    if (userInfoRes['ok'] != true || passbookRes['ok'] != true || rateRes['ok'] != true) {
      return {'ok': false, 'message': 'Failed to load certificate data'};
    }

    final userInfo = userInfoRes['userInfo'] as Map<String, dynamic>? ?? {};
    final passbook = passbookRes['passbook'] as Map<String, dynamic>? ?? {};
    final rawSnapshot = rateRes['snapshot'];
    final rateObj = rawSnapshot is GoldRate ? rawSnapshot : null;
    final buyOrders = (buyOrdersRes['orders'] as List?)?.cast<AugmontOrder>() ?? <AugmontOrder>[];

    // Deep-nested extraction like React's normalizeAugmontUserInfo
    final payload = userInfo['payload'] as Map<String, dynamic>? ?? userInfo;
    final result = payload['result'] as Map<String, dynamic>? ?? payload;
    final resultData = result['data'] as Map<String, dynamic>? ?? result;
    final userInfoOuter = resultData['userInfo'] as Map<String, dynamic>? ?? resultData;
    final prof = userInfoOuter['profile'] as Map<String, dynamic>? ?? userInfoOuter;
    final source = {...resultData, ...userInfoOuter, ...prof};

    final extractedName = _str(prof['fullName'] ?? prof['userName'] ?? prof['name'] ?? source['fullName'] ?? source['userName'] ?? source['name'] ?? '');
    final extractedEmail = _str(prof['email'] ?? prof['userEmail'] ?? prof['emailId'] ?? source['email'] ?? source['userEmail'] ?? source['emailId'] ?? '');
    final extractedMobile = _str(prof['mobileNumber'] ?? prof['mobile'] ?? prof['mobileNo'] ?? source['mobileNumber'] ?? source['mobile'] ?? source['mobileNo'] ?? '');
    final storedPan = LocalStorageService.getUserPan() ?? '';
    final panRaw = storedPan.isNotEmpty ? storedPan : _str(prof['pan'] ?? prof['panNumber'] ?? source['pan'] ?? source['panNumber'] ?? '');
    final extractedCustomerId = _str(prof['uniqueId'] ?? source['uniqueId'] ?? resultData['uniqueId'] ?? resultData['customerUniqueId'] ?? uid);

    // Filter for silver orders
    final silverOrders = buyOrders.where((o) => o.metalType == 'silver' || o.type == 'silver').toList();
    if (silverOrders.isEmpty) {
      silverOrders.addAll(buyOrders);
    }

    final invData = investRes['data'] as Map<String, dynamic>? ?? investRes;
    final holdingWM = _safeNum(invData['currentHoldingWithMultiplier']);
    final totalSellGrams = _safeNum(invData['totalSellGrams']);
    final silverBalance = _safeNum(passbook['silverGrms'] ?? passbook['silverBalance'] ?? passbook['silver']);
    final buyPrice = rateObj?.silver.buyPrice ?? rateObj?.buyPrice ?? 0;
    final portfolioValue = holdingWM * buyPrice;

    silverOrders.sort((a, b) => (DateTime.tryParse(b.date) ?? DateTime(2000)).compareTo(DateTime.tryParse(a.date) ?? DateTime(2000)));

    AugmontOrder? latest = silverOrders.isNotEmpty ? silverOrders.first : null;
    final latestDateStr = latest?.date.isNotEmpty == true ? latest!.date : DateTime.now().toIso8601String();

    final lp = CertificateLatestPurchase(
      transactionId: latest?.orderReference ?? '',
      purchaseDate: _fmtDate(latestDateStr), purchaseTime: _fmtTime(latestDateStr),
      quantity: latest?.gold ?? 0, rate: latest?.rate ?? 0, amount: latest?.amount ?? 0,
      gst: _safeNum(latest?.taxAmt) != 0 ? _safeNum(latest!.taxAmt) : ((latest?.amount ?? 0) * 0.03),
      paymentMethod: '', paymentStatus: latest?.status ?? 'Success',
    );

    final history = silverOrders.take(5).map((o) => CertificateHistoryItem(
      date: _fmtDate(o.date), transactionId: o.orderReference,
      quantity: o.gold, rate: o.rate, amount: o.amount, status: o.status,
    )).toList();

    final certNum = (certificateNumber ?? (lp.transactionId.isNotEmpty ? lp.transactionId : null) ?? uid).trim();
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    final cert = CertificateData(
      certificateNumber: certNum.isNotEmpty ? certNum : uid,
      issueDate: '${now.day} ${months[now.month - 1]} ${now.year}',
      certificateType: 'Overall Holding Certificate',
      verificationUrl: 'https://karatly.com/verify',
      verificationHash: _verHash(certNum.isNotEmpty ? certNum : uid),
      customer: CertificateCustomerInfo(
        name: extractedName,
        customerId: extractedCustomerId,
        mobileNumber: extractedMobile,
        email: extractedEmail,
        panMasked: _maskPan(panRaw),
      ),
      portfolio: CertificatePortfolioSummary(
        totalGoldPortfolioGrams: silverBalance,
        totalGoldPortfolioValue: portfolioValue,
        totalDigitalGoldRedeemSold: totalSellGrams,
        currentGoldRate: buyPrice,
      ),
      latestPurchase: lp,
      purchaseHistory: history,
      holdingSummary: CertificateHoldingSummary(
        totalGoldPortfolio: silverBalance,
        totalDigitalGoldRedeemSold: totalSellGrams,
        availableForRedemption: silverBalance,
        vaultStorage: 'Secured & Insured', goldPurity: '999 Fine Silver',
        storagePartner: 'Augmont Vaults', insuranceCoverage: '100% Insured',
      ),
      certificateNote: "This certificate confirms that the above-mentioned digital silver is owned by the customer and is held in secure and insured vaults by Augmont. The silver is mapped to the customer's account and can be redeemed or sold as per the applicable terms and conditions of Karatly and Augmont.",
    );
    return {'ok': true, 'certificate': cert};
  } catch (e) {
    return {'ok': false, 'message': 'Failed to load certificate details.'};
  }
}

// ── Diamond Certificate ──

class DiamondCustomerInfo {
  final String name;
  final String customerId;
  final String mobileNumber;
  final String email;
  final String panMasked;
  const DiamondCustomerInfo({this.name = '', this.customerId = '', this.mobileNumber = '', this.email = '', this.panMasked = ''});
}

class DiamondOrderHistoryItem {
  final String date;
  final String transactionId;
  final String diamond;
  final String amount;
  final String status;
  const DiamondOrderHistoryItem({this.date = '', this.transactionId = '', this.diamond = '', this.amount = '', this.status = ''});
}

class DiamondCertificateData {
  final String certificateNumber;
  final String issueDate;
  final String certificateType;
  final String verificationUrl;
  final String verificationHash;
  final DiamondCustomerInfo customer;
  final DiamondOrderHistoryItem latestPurchase;
  final List<DiamondOrderHistoryItem> orderHistory;
  final String totalInvestment;
  final int totalOrders;
  final String certificateNote;
  const DiamondCertificateData({this.certificateNumber = '', this.issueDate = '', this.certificateType = '', this.verificationUrl = '', this.verificationHash = '', this.customer = const DiamondCustomerInfo(), this.latestPurchase = const DiamondOrderHistoryItem(), this.orderHistory = const [], this.totalInvestment = '', this.totalOrders = 0, this.certificateNote = ''});
}

Future<Map<String, dynamic>> getDiamondCertificate() async {
  final profile = LocalStorageService.getUserProfile() ?? <String, dynamic>{};
  final name = (profile['fullName'] ?? profile['name'] ?? '').toString();
  final mobile = (profile['mobileNumber'] ?? '').toString();
  final email = (profile['email'] ?? '').toString();
  final uid = (profile['uniqueId'] ?? profile['augmontUniqueId'] ?? '').toString();
  final pan = LocalStorageService.getUserPan() ?? '';

  final diamDio = Dio(BaseOptions(connectTimeout: Duration(seconds: 30), receiveTimeout: Duration(seconds: 30), headers: {'Content-Type': 'application/json'}));
  final diamondApi = DiamondApi(diamDio);
  try {
    final results = await Future.wait([
      diamondApi.fetchDiamondOrders(),
      diamondApi.fetchDiamondProducts(from: 0, to: 500),
    ]);

    final ordersRes = results[0] as Map<String, dynamic>;
    final productsRes = results[1] as Map<String, dynamic>;

    // Build product map
    final productData = productsRes['data'] as Map<String, dynamic>? ?? productsRes;
    final productList = productData['products'] as List? ?? productData['data'] as List? ?? [];
    final Map<String, Map<String, dynamic>> productMap = {};
    for (final p in productList) {
      if (p is Map) {
        final id = p['id']?.toString() ?? p['productId']?.toString() ?? '';
        if (id.isNotEmpty) productMap[id] = Map<String, dynamic>.from(p);
      }
    }

    // Parse orders
    final orderData = ordersRes['data'] as Map<String, dynamic>? ?? ordersRes;
    final orderList = orderData['orders'] as List? ?? orderData['data'] as List? ?? [];
    final sorted = List<Map<String, dynamic>>.from(orderList.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}));

    sorted.sort((a, b) {
      final aD = DateTime.tryParse(a['createdAt']?.toString() ?? a['date']?.toString() ?? '') ?? DateTime(2000);
      final bD = DateTime.tryParse(b['createdAt']?.toString() ?? b['date']?.toString() ?? '') ?? DateTime(2000);
      return bD.compareTo(aD);
    });

    final latest = sorted.isNotEmpty ? sorted.first : <String, dynamic>{};
    final latestDate = latest['createdAt']?.toString() ?? latest['date']?.toString() ?? DateTime.now().toIso8601String();

    String _diamondName(Map<String, dynamic> order) {
      final pid = order['productId']?.toString() ?? '';
      final product = productMap[pid];
      if (product != null) {
        final shape = product['shape']?.toString() ?? '';
        final carat = product['carat']?.toString() ?? '';
        return '$shape $carat ct'.trim();
      }
      final snap = order['pricingSnapshot'];
      if (snap is Map) {
        final s = snap['shape']?.toString() ?? '';
        final c = snap['carat']?.toString() ?? '';
        return '$s $c ct'.trim();
      }
      return 'Diamond';
    }

    double _orderAmt(Map<String, dynamic> order) {
      return _safeNum(order['totalAmount'] ?? order['amount'] ?? order['totalPrice']);
    }

    String _fmtAmt(double v) {
      return '₹${v.toStringAsFixed(0)}';
    }

    final latestItem = DiamondOrderHistoryItem(
      date: _fmtDate(latestDate),
      transactionId: latest['orderReference']?.toString() ?? latest['transactionId']?.toString() ?? latest['id']?.toString() ?? '',
      diamond: _diamondName(latest),
      amount: _fmtAmt(_orderAmt(latest)),
      status: latest['status']?.toString() ?? 'Success',
    );

    final orderHistory = sorted.take(5).map((o) => DiamondOrderHistoryItem(
      date: _fmtDate(o['createdAt']?.toString() ?? o['date']?.toString() ?? ''),
      transactionId: o['orderReference']?.toString() ?? o['transactionId']?.toString() ?? o['id']?.toString() ?? '',
      diamond: _diamondName(o),
      amount: _fmtAmt(_orderAmt(o)),
      status: o['status']?.toString() ?? 'Success',
    )).toList();

    final totalInvestment = sorted.fold<double>(0, (s, o) => s + _orderAmt(o));
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final certNum = latestItem.transactionId.isNotEmpty ? latestItem.transactionId : uid;

    final cert = DiamondCertificateData(
      certificateNumber: certNum,
      issueDate: '${now.day} ${months[now.month - 1]} ${now.year}',
      certificateType: 'Diamond Purchase Certificate',
      verificationUrl: 'https://karatly.com/verify',
      verificationHash: _verHash(certNum),
      customer: DiamondCustomerInfo(name: name, customerId: uid, mobileNumber: mobile, email: email, panMasked: _maskPan(pan)),
      latestPurchase: latestItem,
      orderHistory: orderHistory,
      totalInvestment: _fmtAmt(totalInvestment),
      totalOrders: sorted.length,
      certificateNote: "This certificate confirms that the above-mentioned diamond(s) have been purchased by the customer through Karatly. Each diamond is independently certified and comes with its own grading report. The diamonds are sourced from reputable suppliers and are genuine natural diamonds.",
    );
    return {'ok': true, 'certificate': cert};
  } catch (e) {
    return {'ok': false, 'message': 'Failed to load certificate details.'};
  }
}

class DioProvider {
  static final _dio = Dio(BaseOptions(connectTimeout: Duration(seconds: 30), receiveTimeout: Duration(seconds: 30), headers: {'Content-Type': 'application/json'}));
  static Dio createDio() {
    final token = LocalStorageService.getToken();
    if (token != null && token.isNotEmpty) _dio.options.headers['Authorization'] = 'Bearer $token';
    return _dio;
  }
}
