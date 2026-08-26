import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/gold_rate_model.dart';
import '../models/augmont_model.dart';
import '../models/product_model.dart';
import '../storage/local_storage.dart';
import '../utils/constants.dart';
import 'config.dart';

class AugmontApi {
  final Dio _dio;

  AugmontApi(this._dio);

  // ── Rate caching ──
  static final Map<String, dynamic> _rateCache = {};
  static DateTime? _rateCacheExpiry;

  static bool _isRateCacheValid() {
    if (_rateCacheExpiry == null) return false;
    return DateTime.now().isBefore(_rateCacheExpiry!);
  }

  static void _setRateCache(String key, dynamic value) {
    _rateCache[key] = value;
    _rateCacheExpiry = DateTime.now().add(AppConstants.rateCacheTtl);
  }

  // ── Helpers ──
  Map<String, dynamic> _getJson(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    final text = data?.toString() ?? '';
    try {
      return text.isNotEmpty ? jsonDecode(text) : {};
    } catch (_) {
      return {
        'status': 'error',
        'payload': {'statusCode': res.statusCode, 'message': text.isNotEmpty ? text : 'Invalid server response'},
      };
    }
  }

  String _extractBackendMessage(Map<String, dynamic> data, [String fallback = 'Request failed']) {
    final payload = data['payload'] as Map<String, dynamic>?;
    final payloadMsg = payload?['message']?.toString();
    final responseBody = payload?['responseBody']?.toString();

    if (responseBody != null && responseBody.isNotEmpty) {
      try {
        final parsed = jsonDecode(responseBody);
        if (parsed is Map && parsed['message'] != null) return parsed['message'].toString();
      } catch (_) {}
      return responseBody;
    }

    if (payloadMsg != null && payloadMsg.contains('<')) {
      final msgMatch = RegExp(r'<b>Message</b>\s*([^<]+)', caseSensitive: false).firstMatch(payloadMsg);
      if (msgMatch != null) return msgMatch.group(1)?.trim() ?? payloadMsg;
      final descMatch = RegExp(r'<b>Description</b>\s*([^<]+)', caseSensitive: false).firstMatch(payloadMsg);
      if (descMatch != null) return descMatch.group(1)?.trim() ?? payloadMsg;
    }

    return payloadMsg ?? data['message']?.toString() ?? fallback;
  }

  String _extractStatusCode(Map<String, dynamic> data) {
    return ((data['payload'] as Map<String, dynamic>?)?['statusCode']?.toString()) ??
        data['statusCode']?.toString() ??
        data['code']?.toString() ??
        '';
  }

  double _pickFirstPositiveNumber(List<dynamic> values) {
    for (final value in values) {
      final parsed = double.tryParse(value?.toString() ?? '') ?? 0;
      if (parsed > 0) return parsed;
    }
    return 0;
  }

  double _toNumber(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed.isFinite ? parsed : 0;
  }

  // ── Core request ──
  String _extractBankRecordId(Map<String, dynamic> bank) {
    final raw = (
      bank['provider_bank_id']?.toString() ??
      bank['userBankId']?.toString() ??
      bank['bankId']?.toString() ??
      bank['id']?.toString() ??
      ''
    ).trim();
    return raw.replaceAll(RegExp(r'[()]'), '');
  }

  Map<String, dynamic>? _normalizeBankRecord(Map<String, dynamic>? bank) {
    if (bank == null) return null;

    final bankId = _extractBankRecordId(bank);
    final bankName = (bank['bankName'] ?? bank['bank_name'] ?? bank['bank'] ?? '').toString().trim();
    final accountNumber = (bank['accountNumber'] ?? bank['account_number'] ?? bank['bankNumber'] ?? bank['bank_number'] ?? '').toString().trim();
    final accountType = (bank['accountType'] ?? bank['account_type'] ?? 'Savings').toString().trim();
    final ifsc = (bank['ifscCode'] ?? bank['ifsc_code'] ?? bank['ifsc'] ?? '').toString().trim().toUpperCase();
    final isPrimary = bank['isPrimary'] == true || bank['is_primary'] == true;

    return <String, dynamic>{
      ...bank,
      if (bankId.isNotEmpty) 'userBankId': bankId,
      if (bankId.isNotEmpty) 'provider_bank_id': bankId,
      if (bankName.isNotEmpty) 'bankName': bankName,
      if (bankName.isNotEmpty) 'bank_name': bankName,
      if (bankName.isNotEmpty) 'bank': bankName,
      if (accountNumber.isNotEmpty) 'accountNumber': accountNumber,
      if (accountNumber.isNotEmpty) 'account_number': accountNumber,
      if (accountType.isNotEmpty) 'accountType': accountType,
      if (accountType.isNotEmpty) 'account_type': accountType,
      if (ifsc.isNotEmpty) 'ifscCode': ifsc,
      if (ifsc.isNotEmpty) 'ifsc_code': ifsc,
      if (ifsc.isNotEmpty) 'ifsc': ifsc,
      'isPrimary': isPrimary,
      'is_primary': isPrimary,
    };
  }

  Map<String, dynamic>? _extractPrimaryBankRecord(dynamic source) {
    final candidates = <dynamic>[
      source,
      source is Map<String, dynamic> ? source['payload'] : null,
      source is Map<String, dynamic> ? source['data'] : null,
      source is Map<String, dynamic> ? source['bank'] : null,
      source is Map<String, dynamic> ? source['primaryBank'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;

      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map) {
            final record = Map<String, dynamic>.from(item);
            if (record['isPrimary'] == true || record['is_primary'] == true) {
              return _normalizeBankRecord(record);
            }
          }
        }
        if (candidate.isNotEmpty && candidate.first is Map) {
          return _normalizeBankRecord(Map<String, dynamic>.from(candidate.first as Map));
        }
      }

      if (candidate is Map) {
        final record = Map<String, dynamic>.from(candidate);
        final nestedBanks = record['banks'] ?? record['bankAccounts'] ?? record['data'];
        if (nestedBanks is List && nestedBanks.isNotEmpty) {
          for (final item in nestedBanks) {
            if (item is Map) {
              final nested = Map<String, dynamic>.from(item);
              if (nested['isPrimary'] == true || nested['is_primary'] == true) {
                return _normalizeBankRecord(nested);
              }
            }
          }
          final first = nestedBanks.first;
          if (first is Map) return _normalizeBankRecord(Map<String, dynamic>.from(first));
        }

        if (_extractBankRecordId(record).isNotEmpty ||
            record['accountNumber'] != null ||
            record['account_number'] != null ||
            record['bankName'] != null ||
            record['bank_name'] != null) {
          return _normalizeBankRecord(record);
        }
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> _requestAugmontOrderEndpoint(
    String path,
    Map<String, dynamic> body, [
    String fallbackMessage = 'Failed to complete order request',
  ]) async {
    try {
      final merchantId = body['merchantId']?.toString() ?? ApiConfig.defaultMerchantId;
      final token = LocalStorageService.getToken() ?? '';
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}$path',
        data: {'merchantId': merchantId, ...body},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      final data = _getJson(res);
      final statusCode = _extractStatusCode(data);
      final backendStatus = (data['status']?.toString() ?? '').toUpperCase();
      final isPaymentDetailsStatus = path == '/api/v1/paymentdetails' &&
          ['SUCCESS', 'FAILED', 'PENDING', 'PROCESSING'].contains(backendStatus);
      final isMinimalSuccess = (res.statusCode != null && res.statusCode! < 400) &&
          (isPaymentDetailsStatus ||
              backendStatus == 'SUCCESS' ||
              data['status'] == 'success' ||
              data['status'] == null ||
              statusCode.startsWith('2') ||
              RegExp(r'success', caseSensitive: false)
                  .hasMatch(data['message']?.toString() ?? (data['payload'] as Map<String, dynamic>?)?['message']?.toString() ?? ''));

      if (!isMinimalSuccess) {
        return {
          'ok': false,
          'statusCode': statusCode,
          'httpStatus': res.statusCode,
          'message': _extractBackendMessage(data, fallbackMessage),
          'data': data,
          'raw': data,
        };
      }
      return {'ok': true, 'statusCode': statusCode, 'data': data, 'raw': data};
    } catch (error) {
      return {'ok': false, 'message': fallbackMessage};
    }
  }

  // ── Rate normalization ──
  GoldRate normalizeGoldRatePayload(Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    final resultData = result?['data'] as Map<String, dynamic>?;
    final rates = (resultData?['rates'] as Map<String, dynamic>?) ??
        (result?['rates'] as Map<String, dynamic>?) ??
        (payload?['rates'] as Map<String, dynamic>?) ??
        (data['rates'] as Map<String, dynamic>?) ??
        {};

    final buyPrice = _pickFirstPositiveNumber([
      rates['gBuy'], rates['buy'], rates['buyPrice'], rates['goldBuy'], rates['gold_buy'],
    ]);
    final sellPrice = _pickFirstPositiveNumber([
      rates['gSell'], rates['sell'], rates['sellPrice'], rates['goldSell'], rates['gold_sell'],
    ]);
    final currentPrice = _pickFirstPositiveNumber([rates['current'], rates['price'], rates['goldPrice'], buyPrice, sellPrice]);

    final blockId = (resultData?['blockId']?.toString()) ??
        (result?['blockId']?.toString()) ??
        (data['blockId']?.toString()) ??
        '';

    return GoldRate(
      currentPrice: currentPrice,
      buyPrice: buyPrice > 0 ? buyPrice : currentPrice,
      sellPrice: sellPrice > 0 ? sellPrice : currentPrice,
      blockId: blockId,
      metalType: rates['metalType']?.toString() ?? 'gold',
      updatedAt: rates['updatedAt']?.toString() ?? rates['timestamp']?.toString() ?? (resultData?['updatedAt']?.toString()) ?? DateTime.now().toIso8601String(),
      gold: GoldRateMeta(
        currentPrice: currentPrice,
        buyPrice: buyPrice > 0 ? buyPrice : currentPrice,
        sellPrice: sellPrice > 0 ? sellPrice : currentPrice,
      ),
      silver: GoldRateMeta(
        currentPrice: _pickFirstPositiveNumber([rates['sCurrent'], rates['silverCurrent'], rates['silverPrice'], rates['sPrice']]),
        buyPrice: _pickFirstPositiveNumber([rates['sBuy'], rates['silverBuy'], rates['silver_buy'], rates['silverBuyPrice']]),
        sellPrice: _pickFirstPositiveNumber([rates['sSell'], rates['silverSell'], rates['silver_sell'], rates['silverSellPrice']]),
      ),
    );
  }

  // ── Live rates ──
  Future<Map<String, dynamic>> getGoldRates() async {
    try {
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/rates/live',
        data: {'merchantId': ApiConfig.defaultMerchantId},
      );
      return _getJson(res);
    } catch (error) {
      return {'ok': false, 'status': 'error', 'payload': {'message': 'Failed to fetch live Augmont rates'}};
    }
  }

  Future<Map<String, dynamic>> fetchLiveGoldRateSnapshot({bool force = false}) async {
    if (!force && _isRateCacheValid() && _rateCache.containsKey('live')) {
      return {'ok': true, 'snapshot': _rateCache['live'], 'fromCache': true};
    }

    try {
      final data = await getGoldRates();
      final snapshot = normalizeGoldRatePayload(data);
      if (snapshot.currentPrice <= 0) {
        return {'ok': false, 'message': _extractBackendMessage(data, 'Live gold rate is unavailable'), 'snapshot': snapshot};
      }
      _setRateCache('live', snapshot);
      await LocalStorageService.setGoldPrice(snapshot.currentPrice);
      return {'ok': true, 'snapshot': snapshot, 'blockId': snapshot.blockId};
    } catch (error) {
      return {'ok': false, 'message': 'Failed to fetch live gold rate'};
    }
  }

  // ── Rate history ──
  Future<Map<String, dynamic>> fetchAugmontRateHistory({
    String? fromDate,
    String? toDate,
    String metalType = 'gold',
    bool force = false,
  }) async {
    final cacheKey = 'history:$fromDate:$toDate:$metalType';
    if (!force && _isRateCacheValid() && _rateCache.containsKey(cacheKey)) {
      return {'ok': true, 'history': _rateCache[cacheKey], 'fromCache': true};
    }

    try {
      if (fromDate == null || toDate == null) throw Exception('Missing dates');
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/rates/history',
        data: {
          'merchantId': ApiConfig.defaultMerchantId,
          'fromDate': fromDate,
          'toDate': toDate,
          'metalType': metalType,
        },
      );
      final data = _getJson(res);
      final history = _normalizeRateHistoryPayload(data, metalType);
      if (history.isEmpty) {
        return {'ok': false, 'history': history, 'message': _extractBackendMessage(data, 'Historical rates unavailable')};
      }
      _setRateCache(cacheKey, history);
      return {'ok': true, 'history': history};
    } catch (error) {
      return {'ok': false, 'history': <RateHistoryPoint>[], 'message': 'Failed to fetch historical rates'};
    }
  }

  List<RateHistoryPoint> _normalizeRateHistoryPayload(Map<String, dynamic> data, String metalType) {
    final payload = data['payload'] as Map<String, dynamic>?;
    final result = payload?['result'];
    List<dynamic> source = [];
    if (result is List) {
      source = result;
    } else if (result is Map && result['data'] is List) {
      source = result['data'] as List;
    }

    return source
        .map((item) {
          final map = item as Map<String, dynamic>;
          final buyRate = _toNumber(map['buyRate']);
          final sellRate = _toNumber(map['sellRate']);
          return RateHistoryPoint(
            date: map['date']?.toString() ?? '',
            metalType: map['type']?.toString() ?? metalType,
            buyRate: buyRate,
            sellRate: sellRate,
            label: map['date']?.toString() ?? '',
            price: buyRate > 0 ? buyRate : sellRate,
            updatedAt: map['date']?.toString() ?? '',
          );
        })
        .where((item) => item.buyRate > 0 || item.sellRate > 0)
        .toList();
  }

  // ── SIP rates ──
  Future<Map<String, dynamic>> fetchAugmontSipRates() async {
    const cacheKey = 'sip';
    if (_isRateCacheValid() && _rateCache.containsKey(cacheKey)) {
      return {'ok': true, 'snapshot': _rateCache[cacheKey], 'fromCache': true};
    }

    try {
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/rates/sip',
        data: {'merchantId': ApiConfig.defaultMerchantId},
      );
      final data = _getJson(res);
      final payload = data['payload'] as Map<String, dynamic>?;
      final result = payload?['result'] as Map<String, dynamic>?;
      final resultData = result?['data'] as Map<String, dynamic>?;
      final rates = (resultData?['rates'] as Map<String, dynamic>?) ??
          (result?['rates'] as Map<String, dynamic>?) ??
          (payload?['rates'] as Map<String, dynamic>?) ??
          {};

      final snapshot = SipRateSnapshot(
        gold: GoldRateMeta(
          currentPrice: _pickFirstPositiveNumber([rates['gBuy'], rates['goldSipRate'], rates['goldRate'], rates['buy'], rates['buyPrice']]),
          buyPrice: _pickFirstPositiveNumber([rates['gBuy'], rates['goldSipRate'], rates['goldRate'], rates['buy'], rates['buyPrice']]),
        ),
        silver: GoldRateMeta(
          currentPrice: _pickFirstPositiveNumber([rates['sBuy'], rates['silverSipRate'], rates['silverRate'], rates['silverBuy']]),
          buyPrice: _pickFirstPositiveNumber([rates['sBuy'], rates['silverSipRate'], rates['silverRate'], rates['silverBuy']]),
        ),
        updatedAt: rates['updatedAt']?.toString() ?? (resultData?['updatedAt']?.toString()) ?? DateTime.now().toIso8601String(),
      );

      _setRateCache(cacheKey, snapshot);
      return {'ok': true, 'snapshot': snapshot};
    } catch (error) {
      return {'ok': false, 'snapshot': const SipRateSnapshot(), 'message': 'Failed to fetch SIP rates'};
    }
  }

  // ── User profile ──
  Future<Map<String, dynamic>> fetchAugmontUserProfile(String uniqueId) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing Augmont uniqueId'};
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/profile', {'uniqueId': uniqueId});
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    final profileData = (result?['data'] ?? result ?? (response['data'] as Map<String, dynamic>?)?['data'] ?? {}) as Map<String, dynamic>;
    final normalized = AugmontUserProfile.fromJson(profileData);
    await LocalStorageService.setAugmontUser(jsonEncode(profileData));
    return {'ok': true, 'profile': normalized, 'raw': response['raw']};
  }

  Future<Map<String, dynamic>> fetchAugmontUserInfo({required String uniqueId}) async {
    if (uniqueId.trim().isEmpty) return {'ok': false, 'message': 'Missing Augmont uniqueId', 'userInfo': null};
    try {
      final token = LocalStorageService.getToken() ?? '';
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/users/info',
        data: {'uniqueId': uniqueId.trim()},
        options: Options(headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        }),
      );
      final data = _getJson(res);
      if ((res.statusCode ?? 500) >= 400 || data['ok'] == false || data['status'] == 'error') {
        return {'ok': false, 'message': _extractBackendMessage(data, 'Failed to fetch user info'), 'userInfo': null};
      }
      return {'ok': true, 'userInfo': data};
    } catch (error) {
      return {'ok': false, 'message': 'Failed to fetch user info', 'userInfo': null};
    }
  }

  // ── User create/update ──
  Future<Map<String, dynamic>> createAugmontUser(Map<String, dynamic> request, [String? merchantId]) async {
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/create', {
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'request': request,
    });
    if (!response['ok']) return response;
    final payload = (response['raw'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    return {
      'ok': true,
      'message': payload?['message']?.toString() ?? 'Augmont user create request accepted',
      'raw': response['raw'],
    };
  }

  Future<Map<String, dynamic>> updateAugmontUser({
    required String uniqueId,
    required Map<String, dynamic> request,
    String? merchantId,
  }) => _requestAugmontOrderEndpoint('/api/v1/users/update', {
    'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
    'uniqueId': uniqueId.trim(),
    'request': request,
  });

  // ── KYC ──
  Future<Map<String, dynamic>> fetchAugmontKycProfile(String uniqueId, [String? merchantId]) async {
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/kyc/profile', {
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'uniqueId': uniqueId.trim(),
    });
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    return {'ok': true, 'kycProfile': result?['data'] ?? result ?? {}};
  }

  Future<Map<String, dynamic>> updateAugmontKyc({
    required String uniqueId,
    required Map<String, dynamic> request,
    String? merchantId,
  }) => _requestAugmontOrderEndpoint('/api/v1/users/kyc/update', {
    'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
    'uniqueId': uniqueId.trim(),
    'request': request,
  });

  // ── Bank accounts ──
  Future<Map<String, dynamic>> createAugmontUserBank({
    required String uniqueId,
    required Map<String, dynamic> request,
    String? merchantId,
  }) => _requestAugmontOrderEndpoint('/api/v1/users/banks/create', {
    'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
    'uniqueId': uniqueId.trim(),
    'request': {
      'accountNumber': request['accountNumber']?.toString().trim() ?? '',
      'accountName': request['accountName']?.toString().trim() ?? '',
      'ifscCode': request['ifscCode']?.toString().trim() ?? '',
    },
  });

  Future<Map<String, dynamic>> fetchAugmontUserBanks(String uniqueId, [String? merchantId]) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'banks': []};
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/banks/list', {
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'uniqueId': uniqueId.trim(),
    });
    if (!response['ok']) return {...response, 'banks': []};
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'];
    final banksList = result is List ? result : (result as Map<String, dynamic>?)?['data'] ?? (response['data'] as Map<String, dynamic>?)?['data'] ?? [];
    final banks = banksList is List
        ? banksList
            .whereType<Map>()
            .map((bank) => _normalizeBankRecord(Map<String, dynamic>.from(bank)))
            .whereType<Map<String, dynamic>>()
            .toList()
        : <Map<String, dynamic>>[];
    return {'ok': true, 'banks': banks};
  }

  Future<Map<String, dynamic>> fetchAugmontPrimaryUserBank({required String uniqueId}) async {
    if (uniqueId.trim().isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'bank': null};
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/banks/primary', {
      'merchantId': ApiConfig.defaultMerchantId,
      'uniqueId': uniqueId.trim(),
      'provider_client_reference': uniqueId.trim(),
    });
    if (!response['ok']) return {...response, 'bank': null};
    final bank = _extractPrimaryBankRecord(response['data']);
    return {'ok': true, 'bank': bank, 'banks': bank != null ? [bank] : <Map<String, dynamic>>[]};
  }

  // ── Addresses ──
  Future<Map<String, dynamic>> createAugmontAddress({
    required String uniqueId,
    required Map<String, dynamic> request,
    String? merchantId,
  }) async {
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/addresses/create', {
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'uniqueId': uniqueId.trim(),
      'request': {
        'name': request['name']?.toString().trim() ?? '',
        'mobileNumber': request['mobileNumber']?.toString().trim() ?? '',
        'email': (request['email'] ?? request['emailId'])?.toString().trim() ?? '',
        'address': (request['address'] ?? request['fullAddress'])?.toString().trim() ?? '',
        'landmark': request['landmark']?.toString().trim() ?? '',
        'stateName': (request['stateName'] ?? request['state'])?.toString().trim() ?? '',
        'cityName': (request['cityName'] ?? request['city'])?.toString().trim() ?? '',
        'pincode': (request['pincode'] ?? request['userPincode'])?.toString().trim() ?? '',
      },
    });
    if (!response['ok']) return response;
    final raw = response['raw'] as Map<String, dynamic>? ?? {};
    final payload = raw['payload'] as Map<String, dynamic>?;
    final augmontRes = payload?['augmontResponse'] as Map<String, dynamic>?;
    final innerPayload = augmontRes?['payload'] as Map<String, dynamic>?;
    final resultData = innerPayload?['result'] as Map<String, dynamic>?;
    final data = resultData?['data'] as Map<String, dynamic>?;
    final userAddressId = data?['userAddressId']?.toString() ?? '';
    return {
      'ok': true,
      'message': 'Address created successfully',
      'userAddressId': userAddressId,
      'raw': raw,
    };
  }

  Future<Map<String, dynamic>> fetchAugmontAddresses(String uniqueId, [String? merchantId]) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'addresses': []};
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/addresses/list', {
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'uniqueId': uniqueId.trim(),
    });
    if (!response['ok']) return {...response, 'addresses': []};
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'];
    final addresses = result is List ? result : (result as Map<String, dynamic>?)?['data'] ?? [];
    return {'ok': true, 'addresses': addresses is List ? addresses : []};
  }

  // ── Passbook ──
  Future<Map<String, dynamic>> fetchAugmontPassbook(String uniqueId) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId'};
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/passbook', {'uniqueId': uniqueId.trim()});
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    return {'ok': true, 'passbook': result?['data'] ?? result ?? {}};
  }

  Future<Map<String, dynamic>> createAugmontTransferOrder({
    required Map<String, dynamic> request,
    String? merchantId,
  }) async {
    final response = await _requestAugmontOrderEndpoint('/api/v1/orders/transfer/create', {
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'request': request,
    });
    if (!response['ok']) return response;
    return {'ok': true, 'raw': response['raw'], 'data': response['data']};
  }

  Future<Map<String, dynamic>> createAugmontSellOrder({
    required String merchantId,
    required Map<String, dynamic> request,
  }) async {
    if (request['uniqueId'] == null || request['userBankId'] == null) {
      return {'ok': false, 'message': 'Missing uniqueId or userBankId'};
    }
    return _requestAugmontOrderEndpoint('/api/v1/orders/sell/create', {
      'merchantId': merchantId,
      'request': request,
    });
  }

  Future<Map<String, dynamic>> fetchAugmontSellOrderDetail({
    required String merchantId,
    required String merchantTransactionId,
    required String uniqueId,
  }) async {
    return _requestAugmontOrderEndpoint('/api/v1/orders/sell/detail', {
      'merchantId': merchantId,
      'merchantTransactionId': merchantTransactionId,
      'uniqueId': uniqueId,
    });
  }

  Future<Map<String, dynamic>> initiatePayment({
    String merchantId = ApiConfig.defaultMerchantId,
    required dynamic amount,
    required dynamic quantity,
    required String uniqueId,
    String metalType = 'gold',
    required dynamic lockPrice,
    String? blockId,
    String? showPaymentMode,
    String? sku,
    String? addressId,
  }) async {
    final request = <String, dynamic>{
      'merchantId': merchantId,
      'uniqueId': uniqueId,
      'metalType': metalType,
      'lockPrice': lockPrice,
    };
    if (amount != null && amount.toString().trim().isNotEmpty) request['amount'] = amount;
    if (quantity != null && quantity.toString().trim().isNotEmpty) request['quantity'] = quantity;
    if (blockId != null && blockId.trim().isNotEmpty) request['blockId'] = blockId.trim();
    if (showPaymentMode != null && showPaymentMode.trim().isNotEmpty) request['show_payment_mode'] = showPaymentMode.trim();
    if (sku != null && sku.trim().isNotEmpty) request['sku'] = sku.trim();
    if (addressId != null && addressId.trim().isNotEmpty) request['addressId'] = addressId.trim();

    final response = await _requestAugmontOrderEndpoint('/api/v1/payment', request, 'Payment initiation failed');
    if (!response['ok']) return response;
    return {'ok': true, 'data': response['data'], 'raw': response['raw']};
  }

  Future<Map<String, dynamic>> verifyPaymentDetails({
    required String orderReference,
    required String uniqueId,
  }) async {
    final response = await _requestAugmontOrderEndpoint('/api/v1/paymentdetails', {
      'order_reference': orderReference,
      'unique_id': uniqueId,
    }, 'Payment details are not available yet. Payment is still processing.');
    if (!response['ok']) return response;
    return {'ok': true, 'data': response['data'], 'raw': response['raw']};
  }

  // ── Products ──
  Future<Map<String, dynamic>> fetchAugmontProducts([int page = 1, int count = 10, String? merchantId]) async {
    try {
      final resolvedMerchantId = merchantId ?? ApiConfig.defaultMerchantId;
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/products/list',
        data: {'merchantId': resolvedMerchantId, 'page': page, 'count': count},
      );
      final data = _getJson(res);
      if ((res.statusCode ?? 500) >= 400 || data['status'] != 'success') {
        return {'ok': false, 'message': _extractBackendMessage(data, 'Failed to fetch products'), 'products': [], 'pagination': {}};
      }
      final payload = data['payload'] as Map<String, dynamic>?;
      final result = payload?['result'];
      final rawList = result is List ? result : (result as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
      final products = rawList
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'ok': true,
        'products': products,
        'pagination': result?['pagination'] ?? {},
      };
    } catch (error) {
      return {'ok': false, 'message': 'Failed to fetch products', 'products': [], 'pagination': {}};
    }
  }

  // ── Orders ──
  Future<Map<String, dynamic>> fetchProductOrders(String uniqueId) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'orders': []};
    try {
      final token = LocalStorageService.getToken() ?? '';
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/users/product-orders',
        data: {'uniqueId': uniqueId.trim()},
        options: Options(headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        }),
      );
      final data = _getJson(res);
      if ((res.statusCode ?? 500) >= 400) {
        return {'ok': false, 'message': _extractBackendMessage(data, 'Failed to fetch product orders'), 'orders': []};
      }
      return {
        'ok': true,
        'orders': data['data'] is List ? data['data'] : [],
        'count': data['count'] ?? 0,
      };
    } catch (error) {
      return {'ok': false, 'message': 'Failed to fetch product orders', 'orders': []};
    }
  }

  // ── Order normalization ──
  List<AugmontOrder> _normalizeOrderArray(String source, dynamic result) {
    List<dynamic> sourceList = [];
    if (result is List) {
      sourceList = result;
    } else if (result is Map<String, dynamic>) {
      if (result['orders'] is List) {
        sourceList = result['orders'] as List;
      } else if (result['data'] is List) {
        sourceList = result['data'] as List;
      }
    }
    return sourceList.asMap().entries.map((entry) {
      final order = entry.value as Map<String, dynamic>;
      return _normalizeAugmontOrder(source, order, entry.key);
    }).toList();
  }

  AugmontOrder _normalizeAugmontOrder(String source, Map<String, dynamic> order, [int index = 0]) {
    final firstProduct = (order['product'] is List && (order['product'] as List).isNotEmpty)
        ? order['product'][0] as Map<String, dynamic>
        : <String, dynamic>{};

    final amount = _pickFirstPositiveNumber([
      order['exclTaxAmt'], order['inclTaxAmt'], order['totalAmount'],
      order['amount'], order['buyPrice'], order['sellPrice'],
      order['payableAmount'], order['receivableAmount'],
      firstProduct['amount'], firstProduct['price'],
    ]);

    final grams = _pickFirstPositiveNumber([
      order['qty'], order['metalQuantity'], order['quantity'],
      order['goldAmount'], order['grams'], firstProduct['quantity'],
    ]);

    final rate = _pickFirstPositiveNumber([
      order['exclTaxRate'], order['rate'], order['inclTaxRate'],
      firstProduct['price'],
    ]);

    final transactionId = (order['transactionId'] ?? order['txnId'] ?? order['transactionID'] ?? order['id'] ?? '').toString();
    final merchantTransactionId = (order['merchantTransactionId'] ?? order['merchantTxnId'] ?? order['merchantOrderId'] ?? '').toString();
    final uniqueId = (order['uniqueId'] ?? order['userUniqueId'] ?? order['customerUniqueId'] ?? '').toString();

    final rawStatus = (order['status'] ?? order['orderStatus'] ?? order['transactionStatus'])?.toString();
    String status;
    if (rawStatus != null && rawStatus.isNotEmpty) {
      status = rawStatus.replaceAll(RegExp(r'[_-]+'), ' ');
      status = status.replaceAllMapped(RegExp(r'\b\w'), (Match m) => m.group(0)!.toUpperCase());
    } else if (order['cancelId'] != null) {
      status = 'Cancelled';
    } else {
      status = 'Completed';
    }

    final createdAt = (order['createdAt'] ?? order['transactionDate'] ?? order['orderDate'] ?? order['date'] ?? order['updatedAt'] ?? '').toString();
    final rawType = (order['raw'] is Map ? (order['raw'] as Map)['type'] : order['type'] ?? '').toString().toLowerCase();
    final metalCandidate = (order['metalType'] ?? order['metal'] ?? firstProduct['metalType'] ?? firstProduct['metal'] ?? '').toString().toLowerCase().trim();
    final detected = metalCandidate.isNotEmpty
        ? metalCandidate
        : (rawType == 'gold' || rawType == 'silver' || rawType == 'diamond' ? rawType : '');
    final metalType = detected.contains('silver') ? 'silver' : detected.contains('gold') ? 'gold' : detected.contains('diamond') ? 'diamond' : detected;

    return AugmontOrder(
      id: merchantTransactionId.isNotEmpty ? merchantTransactionId : (transactionId.isNotEmpty ? transactionId : '$source-order-$index'),
      type: source.toUpperCase(),
      amount: amount,
      gold: grams,
      rate: rate,
      taxRate: order['taxRate'],
      taxAmt: order['taxAmt'],
      date: createdAt,
      status: status,
      merchantTransactionId: merchantTransactionId,
      transactionId: transactionId,
      uniqueId: uniqueId,
      metalType: metalType,
    );
  }

  // ── Buy orders ──
  Future<Map<String, dynamic>> fetchAugmontBuyOrders({String? uniqueId}) async {
    if (uniqueId == null || uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'orders': <AugmontOrder>[]};
    final response = await _requestAugmontOrderEndpoint('/api/v1/orders/buy/list', {
      'uniqueId': uniqueId.trim(),
    });
    if (!response['ok']) return {...response, 'orders': <AugmontOrder>[]};
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'];
    final orders = _normalizeOrderArray('buy', result);
    return {'ok': true, 'orders': orders, 'raw': response['raw']};
  }

  // ── Sell orders ──
  Future<Map<String, dynamic>> fetchAugmontSellOrders({String? uniqueId}) async {
    if (uniqueId == null || uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'orders': <AugmontOrder>[]};
    final response = await _requestAugmontOrderEndpoint('/api/v1/orders/sell/list', {
      'uniqueId': uniqueId.trim(),
    });
    if (!response['ok']) return {...response, 'orders': <AugmontOrder>[]};
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'];
    final orders = _normalizeOrderArray('sell', result);
    return {'ok': true, 'orders': orders, 'raw': response['raw']};
  }

  // ── Redeem orders ──
  Future<Map<String, dynamic>> fetchAugmontRedeemOrders({String? uniqueId}) async {
    if (uniqueId == null || uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'orders': <AugmontOrder>[]};
    final response = await _requestAugmontOrderEndpoint('/api/v1/orders/redeem/list', {
      'uniqueId': uniqueId.trim(),
    });
    if (!response['ok']) return {...response, 'orders': <AugmontOrder>[]};
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'];
    final orders = _normalizeOrderArray('redeem', result);
    return {'ok': true, 'orders': orders, 'raw': response['raw']};
  }

  // ── Buy invoice ──
  Future<Map<String, dynamic>> fetchAugmontBuyInvoice({String? transactionId}) async {
    if (transactionId == null || transactionId.isEmpty) return {'ok': false, 'message': 'Missing transactionId'};
    final response = await _requestAugmontOrderEndpoint('/api/v1/invoices/buy', {
      'transactionId': transactionId.trim(),
    });
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    return {'ok': true, 'invoice': result?['data'] ?? result ?? {}, 'raw': response['raw']};
  }

  // ── Sell invoice ──
  Future<Map<String, dynamic>> fetchAugmontSellInvoice({String? transactionId}) async {
    if (transactionId == null || transactionId.isEmpty) return {'ok': false, 'message': 'Missing transactionId'};
    final response = await _requestAugmontOrderEndpoint('/api/v1/invoices/sell', {
      'transactionId': transactionId.trim(),
    });
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    return {'ok': true, 'invoice': result?['data'] ?? result ?? {}, 'raw': response['raw']};
  }

  // ── Redeem invoice ──
  Future<Map<String, dynamic>> fetchAugmontRedeemInvoice({String? transactionId}) async {
    if (transactionId == null || transactionId.isEmpty) return {'ok': false, 'message': 'Missing transactionId'};
    final response = await _requestAugmontOrderEndpoint('/api/v1/invoices/redeem', {
      'transactionId': transactionId.trim(),
    });
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    return {'ok': true, 'invoice': result?['data'] ?? result ?? {}, 'raw': response['raw']};
  }

  // ── Transaction order normalizer (React normalizeTransactionOrder) ──
  AugmontOrder _normalizeTransactionOrder(String source, Map<String, dynamic> order) {
    final pd = (((order['providerResponsePayload'] as Map<String, dynamic>?)
            ?['result'] as Map<String, dynamic>?)
            ?['data'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    final orderType = order['orderType']?.toString() ?? '';
    const typeMap = {'digital_purchase': 'BUY', 'digital_sell': 'SELL', 'physical_redemption': 'REDEEM'};
    final type = typeMap[orderType] ?? source.toUpperCase();

    double amount;
    if (orderType == 'physical_redemption') {
      amount = _pickFirstPositiveNumber([order['shippingAmount'], order['totalAmount']]);
    } else {
      amount = _pickFirstPositiveNumber([pd['preTaxAmount'], order['totalAmount']]);
    }

    final grams = _toNumber(pd['quantity']);
    final rate = _toNumber(pd['rate']);

    final transactionId = (pd['transactionId'] ?? order['orderReference'] ?? '').toString();
    final merchantTransactionId = (order['merchantTransactionId'] ?? '').toString();
    final uniqueId = (pd['uniqueId'] ?? '').toString();

    final itemMetal = (order['item'] as Map<String, dynamic>?)?['catalogMetalType']?.toString() ?? '';
    final metalCandidate = (pd['metalType']?.toString() ?? itemMetal).toLowerCase().trim();
    final metalType = metalCandidate.contains('silver') ? 'silver' : metalCandidate.contains('gold') ? 'gold' : metalCandidate.contains('diamond') ? 'diamond' : metalCandidate;

    final rawStatus = (order['orderStatus'] ?? '').toString();
    String status;
    if (rawStatus.isNotEmpty) {
      status = rawStatus.replaceAll(RegExp(r'[_-]+'), ' ');
      status = status.replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());
    } else {
      status = 'Completed';
    }

    return AugmontOrder(
      id: merchantTransactionId.isNotEmpty ? merchantTransactionId : transactionId,
      type: type,
      amount: amount,
      gold: grams,
      rate: rate,
      date: order['createdAt']?.toString() ?? '',
      status: status,
      merchantTransactionId: merchantTransactionId,
      transactionId: transactionId,
      uniqueId: uniqueId,
      metalType: metalType,
    );
  }

  // ── User transactions (React fetchUserTransactions) ──
  Future<Map<String, dynamic>> fetchUserTransactions({
    required String type,
    required String uniqueId,
    required String metalType,
  }) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId', 'orders': <AugmontOrder>[]};
    final response = await _requestAugmontOrderEndpoint(
      '/api/v1/users/transactions/$type',
      {
        'merchantId': ApiConfig.defaultMerchantId,
        'uniqueId': uniqueId.trim(),
        'metalType': metalType,
      },
    );
    if (!response['ok']) return {...response, 'orders': <AugmontOrder>[]};
    final rawOrders = _extractTransactionOrderArray(response['data']);
    final orders = rawOrders
        .map((o) => _normalizeTransactionOrder(type, o as Map<String, dynamic>))
        .toList();
    return {'ok': true, 'orders': orders, 'raw': response['raw']};
  }

  List<dynamic> _extractTransactionOrderArray(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is! Map<String, dynamic>) return [];
    final result = (data['payload'] as Map<String, dynamic>?)?['result'];
    if (result is List) return result;
    if (result is Map<String, dynamic>) {
      if (result['data'] is List) return result['data'] as List;
      if (result['orders'] is List) return result['orders'] as List;
    }
    final payloadData = (data['payload'] as Map<String, dynamic>?)?['data'];
    if (payloadData is List) return payloadData;
    if (data['data'] is List) return data['data'] as List;
    return [];
  }

  // ── Investment summary ──
  Future<Map<String, dynamic>> fetchInvestmentSummary({required String uniqueId, String metalType = 'gold'}) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId'};
    final response = await _requestAugmontOrderEndpoint('/api/v1/users/investment-summary', {
      'uniqueId': uniqueId.trim(),
      'metalType': metalType,
    });
    if (!response['ok']) return {...response, 'data': null};
    final raw = (response['raw'] ?? response['data'] ?? {}) as Map<String, dynamic>;
    return {
      'ok': true,
      'currentHoldingGrams': _toNumber(raw['currentHoldingGrams']),
      'holdingMultiplier': _toNumber(raw['holdingMultiplier']) == 0 ? 1.0 : _toNumber(raw['holdingMultiplier']),
      'currentHoldingWithMultiplier': _toNumber(raw['currentHoldingWithMultiplier']),
      'totalBuyAmountExclTax': _toNumber(raw['totalBuyAmountExclTax']),
      'totalBuyPreTaxAmount': _toNumber(raw['totalBuyPreTaxAmount']),
      'totalBuyPostTaxAmount': _toNumber(raw['totalBuyPostTaxAmount']),
      'totalSellAmount': _toNumber(raw['totalSellAmount']),
      'totalInvested': _toNumber(raw['totalInvested']),
      'totalInvestedOfGold': _toNumber(raw['totalInvestedOfGold']),
      'totalInvestedOfSilver': _toNumber(raw['totalInvestedOfSilver']),
    };
  }

  // ── Delete bank ──
  Future<Map<String, dynamic>> deleteAugmontUserBank({required String uniqueId, required String userBankId}) async {
    if (uniqueId.isEmpty || userBankId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId or userBankId'};
    return _requestAugmontOrderEndpoint('/api/v1/users/banks/delete', {
      'uniqueId': uniqueId.trim(),
      'userBankId': userBankId.trim(),
    }, 'Failed to delete bank');
  }

  // ── Set primary bank ──
  Future<Map<String, dynamic>> setPrimaryAugmontUserBank({required String uniqueId, required String userBankId}) async {
    final cleanedId = uniqueId.trim();
    final cleanedBank = userBankId.trim();
    if (cleanedId.isEmpty || cleanedBank.isEmpty) return {'ok': false, 'message': 'Missing uniqueId or userBankId'};
    return _requestAugmontOrderEndpoint('/api/v1/users/banks/set-primary', {
      'uniqueId': cleanedId,
      'userBankId': cleanedBank,
      'provider_client_reference': cleanedId,
      'provider_bank_id': cleanedBank,
    }, 'Failed to set primary bank');
  }

  // ── Fetch Aadhaar address ──
  Future<Map<String, dynamic>> downloadTransactionPdf({
    required String type,
    required String uniqueId,
    required String fromDate,
    required String toDate,
  }) async {
    final token = LocalStorageService.getToken() ?? '';
    try {
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/users/transactions/$type/pdf',
        data: {'uniqueId': uniqueId.trim(), 'fromDate': fromDate, 'toDate': toDate},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/pdf',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      if (res.statusCode != null && res.statusCode! >= 400) {
        return {'ok': false, 'message': 'Failed to download $type PDF'};
      }
      final bytes = res.data as List<int>;
      return {'ok': true, 'bytes': bytes, 'fileName': 'KARATLY_${type.toUpperCase()}_Statement_${DateTime.now().millisecondsSinceEpoch}.pdf'};
    } catch (e) {
      return {'ok': false, 'message': 'Failed to download $type PDF'};
    }
  }

  Future<Map<String, dynamic>> fetchAadhaarAddress({required String uniqueId}) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId'};
    return _requestAugmontOrderEndpoint('/api/v1/users/aadhaar/address', {
      'uniqueId': uniqueId.trim(),
    }, 'Failed to fetch Aadhaar address');
  }

  // ── Create UPI ──
  Future<Map<String, dynamic>> createAugmontUpi({
    required String uniqueId,
    required Map<String, dynamic> request,
  }) async {
    if (uniqueId.isEmpty) return {'ok': false, 'message': 'Missing uniqueId'};
    return _requestAugmontOrderEndpoint('/api/v1/users/upi/create', {
      'uniqueId': uniqueId.trim(),
      ...request,
    }, 'Failed to add UPI');
  }

  // ── Fetch States ──
  Future<Map<String, dynamic>> fetchStates() async {
    try {
      final token = LocalStorageService.getToken() ?? '';
      final res = await _dio.get(
        '${ApiConfig.augmontBaseUrl}/api/v1/master/states',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      final data = _getJson(res);
      final payload = data['payload'] as Map<String, dynamic>?;
      final result = payload?['result'] as Map<String, dynamic>?;
      final states = result?['data'] ?? result?['states'];
      return {'ok': true, 'states': states ?? []};
    } catch (e) {
      return {'ok': false, 'message': 'Failed to fetch states', 'states': <dynamic>[]};
    }
  }

  // ── Fetch Cities by State ──
  Future<Map<String, dynamic>> fetchCities({required String stateId}) async {
    if (stateId.isEmpty) return {'ok': false, 'message': 'Missing stateId', 'cities': <dynamic>[]};
    try {
      final token = LocalStorageService.getToken() ?? '';
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/master/cities',
        data: {'stateId': stateId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      final data = _getJson(res);
      final payload = data['payload'] as Map<String, dynamic>?;
      final result = payload?['result'] as Map<String, dynamic>?;
      final cities = result?['data'] ?? result?['cities'];
      return {'ok': true, 'cities': cities ?? []};
    } catch (e) {
      return {'ok': false, 'message': 'Failed to fetch cities', 'cities': <dynamic>[]};
    }
  }
}
