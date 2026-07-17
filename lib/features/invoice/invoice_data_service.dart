import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api/augmont_api.dart';
import '../../core/storage/local_storage.dart';
import '../../core/api/config.dart';

class InvoiceData {
  final String transactionId;
  final String date;
  final String type;
  final String metalType;
  final double quantity;
  final double rate;
  final double amount;
  final double gst;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String customerName;
  final String customerMobile;
  final String customerEmail;
  final String customerState;
  final String pan;
  final String gstin;
  final String address;
  final double balanceBefore;
  final double balanceAfter;
  final String bankName;
  final String bankAccount;
  final String ifsc;
  final String utr;
  final Map<String, dynamic> raw;

  const InvoiceData({
    this.transactionId = '',
    this.date = '',
    this.type = '',
    this.metalType = '',
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.gst = 0,
    this.totalAmount = 0,
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.customerName = '',
    this.customerMobile = '',
    this.customerEmail = '',
    this.customerState = '',
    this.pan = '',
    this.gstin = '',
    this.address = '',
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.bankName = '',
    this.bankAccount = '',
    this.ifsc = '',
    this.utr = '',
    this.raw = const {},
  });
}

String _str(dynamic v) => v?.toString() ?? '';
double _num(dynamic v) {
  if (v == null) return 0;
  final n = double.tryParse(v.toString());
  return (n != null && n.isFinite) ? n : 0;
}

String _maskPan(String pan) {
  final p = pan.trim().toUpperCase();
  if (p.length < 10) return p;
  return '${p.substring(0, 2)}****${p.substring(p.length - 3)}';
}

String _fmtDate(String value) {
  try {
    final dt = DateTime.parse(value);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) { return value; }
}

String _fmtTime(String value) {
  try {
    final dt = DateTime.parse(value);
    final h = dt.hour; final m = dt.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ap';
  } catch (_) { return value; }
}

String getBankNameFromIfsc(String ifsc) {
  final code = ifsc.length >= 4 ? ifsc.substring(0, 4).toUpperCase() : '';
  switch (code) {
    case 'HDFC': return 'HDFC Bank';
    case 'ICIC': return 'ICICI Bank';
    case 'UTIB': return 'Axis Bank';
    case 'SBIN': return 'State Bank of India';
    case 'FDRL': return 'Federal Bank';
    case 'KKBK': return 'Kotak Mahindra Bank';
    case 'CNRB': return 'Canara Bank';
    case 'UBIN': return 'Union Bank of India';
    case 'YESB': return 'Yes Bank';
    default: return ifsc;
  }
}

String resolveInvoiceBankName(String? bankName, String? ifsc) {
  if (bankName != null && bankName.isNotEmpty) return bankName;
  if (ifsc != null && ifsc.isNotEmpty) return getBankNameFromIfsc(ifsc);
  return '';
}

Future<Map<String, dynamic>> fetchInvoiceData({
  required String transactionId,
  required String type,
}) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  final api = AugmontApi(dio);

  try {
    // Fetch invoice from API with retry
    Map<String, dynamic> invoiceRes;
    int attempts = 0;
    do {
      switch (type) {
        case 'buy':
          invoiceRes = await api.fetchAugmontBuyInvoice(transactionId: transactionId);
          break;
        case 'sell':
          invoiceRes = await api.fetchAugmontSellInvoice(transactionId: transactionId);
          break;
        case 'redeem':
          invoiceRes = await api.fetchAugmontRedeemInvoice(transactionId: transactionId);
          break;
        default:
          return {'ok': false, 'message': 'Unknown invoice type: $type'};
      }
      attempts++;
      if (!invoiceRes['ok'] && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } while (!invoiceRes['ok'] && attempts < 3);

    if (!invoiceRes['ok']) {
      return invoiceRes;
    }

    final rawInvoice = invoiceRes['invoice'] as Map<String, dynamic>? ?? invoiceRes['data'] as Map<String, dynamic>? ?? {};
    final raw = invoiceRes['raw'] as Map<String, dynamic>? ?? {};

    // Try nested paths for the actual data
    final payload2 = rawInvoice['payload'] as Map<String, dynamic>? ?? rawInvoice;
    final result2 = payload2['result'] as Map<String, dynamic>? ?? payload2;
    final data = result2['data'] as Map<String, dynamic>? ?? result2;

    // Enrich with user info
    final profile = LocalStorageService.getUserProfile() ?? <String, dynamic>{};
    final uniqueId = (profile['uniqueId'] ?? '').toString();
    final storedPan = LocalStorageService.getUserPan() ?? '';

    // Try fetching user info from API
    String userName = _str(profile['fullName'] ?? profile['name'] ?? '');
    String userMobile = _str(profile['mobileNumber'] ?? '');
    String userEmail = _str(profile['email'] ?? '');
    String userPan = storedPan;
    String userState = _str(profile['state'] ?? profile['stateName'] ?? '');

    if (uniqueId.isNotEmpty) {
      try {
        final userRes = await api.fetchAugmontUserInfo(uniqueId: uniqueId);
        if (userRes['ok'] == true) {
          final ui = userRes['userInfo'] as Map<String, dynamic>? ?? {};
          final pl = ui['payload'] as Map<String, dynamic>? ?? ui;
          final rs = pl['result'] as Map<String, dynamic>? ?? pl;
          final rd = rs['data'] as Map<String, dynamic>? ?? rs;
          final uo = rd['userInfo'] as Map<String, dynamic>? ?? rd;
          final pf = uo['profile'] as Map<String, dynamic>? ?? uo;
          final src = {...rd, ...uo, ...pf};
          userName = _str(pf['fullName'] ?? pf['userName'] ?? pf['name'] ?? src['fullName'] ?? src['userName'] ?? src['name'] ?? userName);
          userMobile = _str(pf['mobileNumber'] ?? pf['mobile'] ?? src['mobileNumber'] ?? src['mobile'] ?? userMobile);
          userEmail = _str(pf['email'] ?? pf['userEmail'] ?? src['email'] ?? src['userEmail'] ?? userEmail);
          userState = _str(pf['state'] ?? pf['stateName'] ?? src['state'] ?? src['stateName'] ?? userState);
          if (userPan.isEmpty) {
            userPan = _str(pf['pan'] ?? pf['panNumber'] ?? src['pan'] ?? src['panNumber'] ?? '');
          }
        }
      } catch (_) {}

      if (userPan.isEmpty) {
        try {
          final kycRes = await api.fetchAugmontKycProfile(uniqueId);
          final kycProfile = kycRes['kycProfile'] as Map<String, dynamic>? ?? {};
          userPan = _str(kycProfile['panNumber'] ?? kycProfile['pan'] ?? '');
        } catch (_) {}
      }
    }

    // Try fetching passbook for balance
    double balanceBefore = _num(data['balanceBefore'] ?? 0);
    double balanceAfter = _num(data['balanceAfter'] ?? 0);
    if (balanceBefore == 0 && balanceAfter == 0 && uniqueId.isNotEmpty) {
      try {
        final pbRes = await api.fetchAugmontPassbook(uniqueId);
        final pb = pbRes['passbook'] as Map<String, dynamic>? ?? {};
        final goldBal = _num(pb['goldGrms'] ?? pb['goldBalance'] ?? pb['gold'] ?? pb['balance'] ?? 0);
        final amount = _num(data['amount'] ?? data['totalAmount'] ?? 0);
        balanceAfter = goldBal;
        balanceBefore = goldBal + amount;
      } catch (_) {}
    }

    // Extract fields from the deep object, merging all response levels
    // Bank fields (accountNumber, ifsc, bankName) may be in nested bankAccount object
    final resultFromRaw = (raw['payload'] as Map<String, dynamic>?)?['result'] as Map<String, dynamic>? ?? {};
    final bankAcct = (resultFromRaw['bankAccount'] as Map<String, dynamic>?) ??
        (data['bankAccount'] as Map<String, dynamic>?) ??
        (rawInvoice['bankAccount'] as Map<String, dynamic>?) ??
        {};
    final invData = <String, dynamic>{
      ...raw,
      ...resultFromRaw,
      ...(data.isNotEmpty ? data : rawInvoice),
      if (bankAcct.isNotEmpty) ...bankAcct, // bankAccount fields override any empty values above
    };

    // Ensure bank fields use the correct keys expected by the PDF builder
    if (invData['ifsc'] == null || (invData['ifsc'] as String?)?.isEmpty == true) {
      if (invData['ifscCode'] != null) invData['ifsc'] = invData['ifscCode'];
    }

    // Build structured data
    final iData = InvoiceData(
      transactionId: _str(invData['transactionId'] ?? invData['merchantTransactionId'] ?? transactionId),
      date: _fmtDate(_str(invData['date'] ?? invData['createdAt'] ?? invData['transactionDate'] ?? '')),
      type: type,
      metalType: _str(invData['metalType'] ?? invData['metal'] ?? invData['type'] ?? type),
      quantity: _num(invData['gold'] ?? invData['quantity'] ?? invData['weight'] ?? 0),
      rate: _num(invData['rate'] ?? invData['price'] ?? 0),
      amount: _num(invData['amount'] ?? invData['subtotal'] ?? invData['totalAmount'] ?? invData['totalPrice'] ?? 0) - _num(invData['taxAmt'] ?? invData['gst'] ?? 0),
      gst: _num(invData['taxAmt'] ?? invData['gst'] ?? invData['gstAmount'] ?? 0),
      totalAmount: _num(invData['totalAmount'] ?? invData['amount'] ?? invData['totalPrice'] ?? 0),
      paymentMethod: resolvePaymentMethod(invData),
      paymentStatus: _str(invData['paymentStatus'] ?? invData['status'] ?? 'Success'),
      customerName: userName,
      customerMobile: userMobile,
      customerEmail: userEmail,
      customerState: userState,
      pan: _maskPan(userPan),
      gstin: _str(invData['gstin'] ?? invData['customerGstin'] ?? ''),
      address: _str(invData['address'] ?? invData['customerAddress'] ?? ''),
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      bankName: resolveInvoiceBankName(
        _str(invData['bankName'] ?? ''),
        _str(invData['ifsc'] ?? invData['bankIfsc'] ?? ''),
      ),
      bankAccount: _str(invData['accountNumber'] ?? invData['bankAccount'] ?? ''),
      ifsc: _str(invData['ifsc'] ?? invData['bankIfsc'] ?? ''),
      utr: _str(invData['utr'] ?? invData['utrNumber'] ?? data['utr'] ?? ''),
      raw: invData,
    );
    return {'ok': true, 'data': iData};
  } catch (e) {
    return {'ok': false, 'message': 'Failed to load invoice: $e'};
  }
}

String resolvePaymentMethod(Map<String, dynamic> invData) {
  final raw = invData['raw'] as Map<String, dynamic>? ?? invData;
  return _str(raw['paymentMethod'] ?? raw['payment_mode'] ?? raw['paymentMethod'] ?? invData['paymentMethod'] ?? invData['paymentMode'] ?? 'UPI');
}
