import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'config.dart';

class CouponResult {
  final bool valid;
  final bool success;
  final bool reserved;
  final String? reservationId;
  final String? couponCode;
  final double discountAmount;
  final double finalPayable;
  final double eligibleSubtotal;
  final String? message;
  final String? orderReference;
  final String? employeeId;
  final String? corporateId;

  const CouponResult({
    this.valid = false,
    this.success = false,
    this.reserved = false,
    this.reservationId,
    this.couponCode,
    this.discountAmount = 0,
    this.finalPayable = 0,
    this.eligibleSubtotal = 0,
    this.message,
    this.orderReference,
    this.employeeId,
    this.corporateId,
  });

  factory CouponResult.fromJson(Map<String, dynamic> json) {
    return CouponResult(
      valid: json['valid'] == true,
      success: json['success'] == true,
      reserved: json['reserved'] == true,
      reservationId: json['reservationId']?.toString(),
      couponCode: json['couponCode']?.toString(),
      discountAmount: _toDouble(json['discountAmount']),
      finalPayable: _toDouble(json['finalPayable']),
      eligibleSubtotal: _toDouble(json['eligibleSubtotal']),
      message: json['message']?.toString(),
      orderReference: json['orderReference']?.toString(),
      employeeId: json['employeeId']?.toString(),
      corporateId: json['corporateId']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class CouponApplyItem {
  final String? itemId;
  final String? brandId;
  final String? brandName;
  final String? sku;
  final String? productCode;
  final int quantity;
  final double price;
  final double? unitPrice;
  final double? lineTotal;

  const CouponApplyItem({
    this.itemId,
    this.brandId,
    this.brandName,
    this.sku,
    this.productCode,
    this.quantity = 1,
    this.price = 0,
    this.unitPrice,
    this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
    if (itemId != null) 'itemId': itemId,
    if (brandId != null) 'brandId': brandId,
    if (brandName != null) 'brandName': brandName,
    if (sku != null) 'sku': sku,
    if (productCode != null) 'product_code': productCode,
    'quantity': quantity,
    'price': price,
    if (unitPrice != null) 'unitPrice': unitPrice,
    if (lineTotal != null) 'lineTotal': lineTotal,
  };
}

class CouponApi {
  final Dio _dio;

  CouponApi(this._dio);

  String get _baseUrl => ApiConfig.augmontBaseUrl;

  Map<String, String> _headers() {
    final token = LocalStorageService.getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(
        '$_baseUrl$path',
        data: body,
        options: Options(headers: _headers()),
      );
      final data = res.data;
      Map<String, dynamic> json;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is Map) {
        json = Map<String, dynamic>.from(data);
      } else {
        json = {};
      }
      final resultData = json['result'];
      Map<String, dynamic> result;
      if (resultData is Map<String, dynamic>) {
        result = resultData;
      } else if (resultData is Map) {
        result = Map<String, dynamic>.from(resultData);
      } else {
        result = json;
      }
      return {
        'ok': res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300,
        'status': res.statusCode,
        'result': CouponResult.fromJson(result),
        'raw': json,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      rethrow;
    }
  }

  /// Validate a coupon (preview discount, no reservation)
  Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    String? clientId,
    required double subtotal,
    double fee = 0,
    List<CouponApplyItem> items = const [],
    String? employeeId,
    String? corporateId,
  }) async {
    return _post('/api/v1/coupons/validate', {
      'couponCode': couponCode,
      if (clientId != null) 'clientId': clientId,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'fee': fee,
      if (employeeId != null) 'employeeId': employeeId,
      if (corporateId != null) 'corporateId': corporateId,
    });
  }

  /// Apply a coupon (reserves it for an order)
  Future<Map<String, dynamic>> applyCoupon({
    required String couponCode,
    required String orderId,
    String? clientId,
    required double subtotal,
    double fee = 0,
    List<CouponApplyItem> items = const [],
    String? employeeId,
    String? corporateId,
  }) async {
    return _post('/api/v1/coupons/apply', {
      'couponCode': couponCode,
      'orderId': orderId,
      if (clientId != null) 'clientId': clientId,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'fee': fee,
      if (employeeId != null) 'employeeId': employeeId,
      if (corporateId != null) 'corporateId': corporateId,
    });
  }

  /// Confirm a coupon after payment success
  Future<Map<String, dynamic>> confirmCoupon({
    required String orderId,
    required String reservationId,
  }) async {
    return _post('/api/v1/coupons/confirm', {
      'reservationId': reservationId,
      'orderId': orderId,
    });
  }

  /// Release a coupon on cancel/failure
  Future<Map<String, dynamic>> releaseCoupon({
    required String reservationId,
  }) async {
    return _post('/api/v1/coupons/release', {
      'reservationId': reservationId,
    });
  }

  static bool isCouponSuccess(CouponResult? result) {
    if (result == null) return false;
    return result.valid || result.success || result.reserved;
  }

  static bool isCouponApplied(CouponResult? result) {
    return result?.reserved == true && result?.reservationId != null;
  }

  static String getErrorMessage(dynamic rawData, [String fallback = 'Could not apply coupon. Please check the code.']) {
    Map<String, dynamic> root;
    if (rawData is Map<String, dynamic>) {
      root = rawData;
    } else if (rawData is Map) {
      root = Map<String, dynamic>.from(rawData);
    } else {
      return fallback;
    }
    final resultData = root['result'];
    Map<String, dynamic> nested;
    if (resultData is Map<String, dynamic>) {
      nested = resultData;
    } else if (resultData is Map) {
      nested = Map<String, dynamic>.from(resultData);
    } else {
      nested = root;
    }
    final message = (nested['message'] ?? root['message'] ?? '').toString().trim();
    if (message.isNotEmpty && message != 'null') return message;
    final error = (root['error'] ?? nested['error'] ?? '').toString().trim();
    if (error.isNotEmpty && error != 'null') return error;
    return fallback;
  }
}
