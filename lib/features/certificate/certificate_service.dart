import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api/augmont_api.dart';
import '../../core/storage/local_storage.dart';
import '../../core/api/config.dart';
import '../../core/models/augmont_model.dart';
import '../../core/models/gold_rate_model.dart';

class CertificateCustomerInfo {
  final String name;
  final String customerId;
  final String mobileNumber;
  final String email;
  final String panMasked;

  const CertificateCustomerInfo({
    this.name = '',
    this.customerId = '',
    this.mobileNumber = '',
    this.email = '',
    this.panMasked = '',
  });
}

class CertificatePortfolioSummary {
  final double totalGoldPurchased;
  final double totalInvestmentAmount;
  final double totalGoldSold;
  final double currentGoldBalance;
  final double averagePurchasePrice;
  final double currentGoldRate;
  final double currentPortfolioValue;
  final double unrealizedGainLoss;
  final double unrealizedGainPercent;

  const CertificatePortfolioSummary({
    this.totalGoldPurchased = 0,
    this.totalInvestmentAmount = 0,
    this.totalGoldSold = 0,
    this.currentGoldBalance = 0,
    this.averagePurchasePrice = 0,
    this.currentGoldRate = 0,
    this.currentPortfolioValue = 0,
    this.unrealizedGainLoss = 0,
    this.unrealizedGainPercent = 0,
  });
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

  const CertificateLatestPurchase({
    this.transactionId = '',
    this.purchaseDate = '',
    this.purchaseTime = '',
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.gst = 0,
    this.paymentMethod = '',
    this.paymentStatus = '',
  });
}

class CertificateHistoryItem {
  final String date;
  final String transactionId;
  final double quantity;
  final double rate;
  final double amount;
  final String status;

  const CertificateHistoryItem({
    this.date = '',
    this.transactionId = '',
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.status = '',
  });
}

class CertificateHoldingSummary {
  final double lifetimePurchased;
  final double lifetimeSold;
  final double currentHolding;
  final double availableForRedemption;
  final String vaultStorage;
  final String goldPurity;
  final String storagePartner;
  final String insuranceCoverage;

  const CertificateHoldingSummary({
    this.lifetimePurchased = 0,
    this.lifetimeSold = 0,
    this.currentHolding = 0,
    this.availableForRedemption = 0,
    this.vaultStorage = '',
    this.goldPurity = '',
    this.storagePartner = '',
    this.insuranceCoverage = '',
  });
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

  const CertificateData({
    this.certificateNumber = '',
    this.issueDate = '',
    this.certificateType = '',
    this.verificationUrl = '',
    this.verificationHash = '',
    this.customer = const CertificateCustomerInfo(),
    this.portfolio = const CertificatePortfolioSummary(),
    this.latestPurchase = const CertificateLatestPurchase(),
    this.purchaseHistory = const [],
    this.holdingSummary = const CertificateHoldingSummary(),
    this.certificateNote = '',
  });
}

String _formatDate(String value) {
  try {
    final dt = DateTime.parse(value);
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return value;
  }
}

String _formatTime(String value) {
  try {
    final dt = DateTime.parse(value);
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $amPm';
  } catch (_) {
    return value;
  }
}

double _safeNum(dynamic value) {
  if (value == null) return 0;
  final n = double.tryParse(value.toString());
  return (n != null && n.isFinite) ? n : 0;
}

String _maskPan(String pan) {
  final plain = pan.trim().toUpperCase();
  if (plain.length < 10) return plain;
  return '${plain.substring(0, 2)}****${plain.substring(plain.length - 3)}';
}

String _buildResolvedUniqueId() {
  final profile = LocalStorageService.getUserProfile() ?? <String, dynamic>{};
  final mobile = (profile['mobileNumber'] ?? '').toString();
  final digits = mobile.replaceAll(RegExp(r'\D'), '');
  final mobile10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  final dob = (profile['dateOfBirth'] ?? '').toString();
  final uniqueId = (profile['uniqueId'] ?? profile['augmontUniqueId'] ?? '').toString().trim();
  if (uniqueId.isNotEmpty) return uniqueId;
  return '$mobile10-$dob';
}

double _extractGold(dynamic order) {
  if (order is Map) {
    return _safeNum(order['gold'] ?? order['grams'] ?? order['weight']);
  }
  return 0;
}

double _extractAmount(dynamic order) {
  if (order is Map) {
    return _safeNum(order['amount'] ?? order['totalAmount'] ?? order['exclTaxAmt']);
  }
  return 0;
}

double _extractRate(dynamic order) {
  if (order is Map) {
    return _safeNum(order['rate'] ?? order['pricePerGram']);
  }
  return 0;
}

String _extractDate(dynamic order) {
  if (order is Map) {
    return order['date']?.toString() ?? order['createdAt']?.toString() ?? '';
  }
  return '';
}

String _extractTransactionId(dynamic order) {
  if (order is Map) {
    return order['merchantTransactionId']?.toString() ?? order['transactionId']?.toString() ?? order['id']?.toString() ?? '';
  }
  return '';
}

String _extractStatus(dynamic order) {
  if (order is Map) {
    return order['status']?.toString() ?? 'Success';
  }
  return 'Success';
}

String _extractPaymentMethod(dynamic order) {
  if (order is Map) {
    final raw = order['raw'];
    if (raw is Map) {
      return raw['paymentMethod']?.toString() ?? raw['paymentMode']?.toString() ?? raw['payment_type']?.toString() ?? 'UPI';
    }
  }
  return 'UPI';
}

Future<Map<String, dynamic>> getCertificate({
  String? uniqueId,
  String? certificateNumber,
}) async {
  final resolvedUniqueId = (uniqueId ?? _buildResolvedUniqueId()).trim();
  if (resolvedUniqueId.isEmpty) {
    return {'ok': false, 'message': 'Unable to resolve the customer unique id. Please login and try again.'};
  }

  final dio = DioProvider.createDio();
  final api = AugmontApi(dio);

  try {
    final results = await Future.wait([
      api.fetchAugmontUserInfo(uniqueId: resolvedUniqueId),
      api.fetchAugmontPassbook(resolvedUniqueId),
      api.fetchAugmontBuyOrders(uniqueId: resolvedUniqueId),
      api.fetchAugmontSellOrders(uniqueId: resolvedUniqueId),
      api.fetchLiveGoldRateSnapshot(),
    ]);

    final userInfoRes = results[0] as Map<String, dynamic>;
    final passbookRes = results[1] as Map<String, dynamic>;
    final buyOrdersRes = results[2] as Map<String, dynamic>;
    final sellOrdersRes = results[3] as Map<String, dynamic>;
    final rateRes = results[4] as Map<String, dynamic>;

    if (userInfoRes['ok'] != true) {
      return {'ok': false, 'message': 'Failed to load customer details'};
    }
    if (passbookRes['ok'] != true) {
      return {'ok': false, 'message': 'Failed to load passbook'};
    }
    if (rateRes['ok'] != true) {
      return {'ok': false, 'message': 'Failed to load gold rate'};
    }

    final userInfo = userInfoRes['userInfo'] as Map<String, dynamic>? ?? {};
    final passbook = passbookRes['passbook'] as Map<String, dynamic>? ?? {};
    final buyOrderList = (buyOrdersRes['orders'] as List?)?.cast<AugmontOrder>() ?? <AugmontOrder>[];
    final sellOrderList = (sellOrdersRes['orders'] as List?)?.cast<AugmontOrder>() ?? <AugmontOrder>[];

    final rawSnapshot = rateRes['snapshot'];
    final goldRateObj = rawSnapshot is GoldRate ? rawSnapshot : null;
    final currentGoldRate = goldRateObj?.buyPrice ?? 0;

    final totalGoldPurchased = buyOrderList.fold<double>(0, (sum, o) => sum + o.gold);
    final totalInvestmentAmount = buyOrderList.fold<double>(0, (sum, o) => sum + o.amount);
    final totalGoldSold = sellOrderList.fold<double>(0, (sum, o) => sum + o.gold);
    final currentGoldBalance = _safeNum(passbook['goldGrms'] ?? passbook['goldBalance'] ?? passbook['gold'] ?? passbook['balance']);
    final avgPurchasePrice = totalGoldPurchased > 0 ? totalInvestmentAmount / totalGoldPurchased : 0;
    final portfolioValue = currentGoldBalance * currentGoldRate;
    final unrealizedGL = (currentGoldRate - avgPurchasePrice) * currentGoldBalance;
    final unrealizedGPct = avgPurchasePrice > 0 ? ((currentGoldRate / avgPurchasePrice - 1) * 100) : 0;

    buyOrderList.sort((a, b) {
      final aDate = DateTime.tryParse(a.date) ?? DateTime(2000);
      final bDate = DateTime.tryParse(b.date) ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    AugmontOrder? latest;
    String latestDateStr;
    if (buyOrderList.isNotEmpty) {
      latest = buyOrderList.first;
      latestDateStr = latest!.date.isNotEmpty ? latest.date : DateTime.now().toIso8601String();
    } else {
      latest = null;
      latestDateStr = DateTime.now().toIso8601String();
    }

    final latestPurchase = CertificateLatestPurchase(
      transactionId: latest?.orderReference ?? '',
      purchaseDate: _formatDate(latestDateStr),
      purchaseTime: _formatTime(latestDateStr),
      quantity: latest?.gold ?? 0,
      rate: latest?.rate ?? 0,
      amount: latest?.amount ?? 0,
      gst: (latest?.taxAmt != null ? _safeNum(latest!.taxAmt) : 0) != 0 ? _safeNum(latest!.taxAmt) : ((latest?.amount ?? 0) * 0.03),
      paymentMethod: '',
      paymentStatus: latest?.status ?? 'Success',
    );

    final history = buyOrderList.take(7).map((o) => CertificateHistoryItem(
      date: _formatDate(o.date),
      transactionId: o.orderReference,
      quantity: o.gold,
      rate: o.rate,
      amount: o.amount,
      status: o.status,
    )).toList();

    final certNum = certificateNumber ?? (latestPurchase.transactionId.isNotEmpty ? latestPurchase.transactionId : null) ?? resolvedUniqueId;
    final certNumber = certNum.trim();
    final verHash = certNumber.length >= 20 ? certNumber.substring(certNumber.length - 20).replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim() : certNumber;

    final pan = LocalStorageService.getUserPan() ?? userInfo['pan']?.toString() ?? userInfo['panNumber']?.toString() ?? '';
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final issueDate = '${now.day} ${months[now.month - 1]} ${now.year}';

    final cert = CertificateData(
      certificateNumber: certNumber.isNotEmpty ? certNumber : resolvedUniqueId,
      issueDate: issueDate,
      certificateType: 'Overall Holding Certificate',
      verificationUrl: 'https://karatly.com/verify',
      verificationHash: verHash.isNotEmpty ? verHash : resolvedUniqueId.substring(resolvedUniqueId.length > 20 ? resolvedUniqueId.length - 20 : 0).replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim(),
      customer: CertificateCustomerInfo(
        name: userInfo['name']?.toString() ?? userInfo['userName']?.toString() ?? userInfo['fullName']?.toString() ?? '',
        customerId: userInfo['uniqueId']?.toString() ?? userInfo['customerUniqueId']?.toString() ?? resolvedUniqueId,
        mobileNumber: userInfo['mobileNumber']?.toString() ?? userInfo['mobile']?.toString() ?? '',
        email: userInfo['email']?.toString() ?? userInfo['emailId']?.toString() ?? '',
        panMasked: _maskPan(pan),
      ),
      portfolio: CertificatePortfolioSummary(
        totalGoldPurchased: totalGoldPurchased,
        totalInvestmentAmount: totalInvestmentAmount,
        totalGoldSold: totalGoldSold,
        currentGoldBalance: currentGoldBalance,
        averagePurchasePrice: avgPurchasePrice.toDouble(),
        currentGoldRate: currentGoldRate.toDouble(),
        currentPortfolioValue: portfolioValue.toDouble(),
        unrealizedGainLoss: unrealizedGL.toDouble(),
        unrealizedGainPercent: unrealizedGPct.toDouble(),
      ),
      latestPurchase: latestPurchase,
      purchaseHistory: history,
      holdingSummary: CertificateHoldingSummary(
        lifetimePurchased: totalGoldPurchased,
        lifetimeSold: totalGoldSold,
        currentHolding: currentGoldBalance,
        availableForRedemption: currentGoldBalance,
        vaultStorage: 'Secured & Insured',
        goldPurity: '24K (999.9 Fine Gold)',
        storagePartner: 'Augmont Vaults',
        insuranceCoverage: '100% Insured',
      ),
      certificateNote: "This certificate confirms that the above-mentioned digital gold is owned by the customer and is held in secure and insured vaults by Augmont. The gold is mapped to the customer's account and can be redeemed or sold as per the applicable terms and conditions of Karatly and Augmont.",
    );

    return {'ok': true, 'certificate': cert};
  } catch (e) {
    return {'ok': false, 'message': 'Failed to load certificate details. Please try again.'};
  }
}

class DioProvider {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  static Dio createDio() {
    final token = LocalStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return _dio;
  }
}
