import 'dart:async';
import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import '../storage/local_storage.dart';
import '../utils/constants.dart';
import 'config.dart';

class CashfreeApi {
  final Dio _dio;

  CashfreeApi(this._dio);

  String get _baseUrl => ApiConfig.augmontBaseUrl;

  Future<T> _post<T>(String path, Map<String, dynamic> body) async {
    final token = LocalStorageService.getToken() ?? '';
    try {
      final res = await _dio.post(
        '$_baseUrl$path',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          receiveTimeout: AppConstants.paymentTimeout,
        ),
      );

      if (res.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      return res.data as T;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Please check your connection and try again.');
      }
      rethrow;
    }
  }

  Future<List<PaymentMethod>> loadPaymentMethods() async {
    try {
      final res = await _post<Map<String, dynamic>>(
        '/api/v1/cfpg/payment/options',
        {},
      );
      final methods = res['methods'] ?? res['data']?['methods'];
      if (methods is List) {
        return methods.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PaymentResponse> createCashfreePayment(PaymentRequest request) async {
    final res = await _post<Map<String, dynamic>>(
      '/api/v1/cfpg/payment',
      request.toJson(),
    );
    return PaymentResponse.fromJson(res);
  }

  Future<PaymentResponse> createDiamondPayment({
    required String clientId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? payment,
  }) async {
    final body = <String, dynamic>{
      'clientId': clientId,
      'totalAmount': totalAmount,
      'items': items,
    };
    if (payment != null) body['payment'] = payment;

    final res = await _post<Map<String, dynamic>>(
      '/api/v1/diamond/cfpg/payment/pg',
      body,
    );
    return PaymentResponse.fromJson(res);
  }

  Future<PaymentStatusResponse> checkPaymentStatus(String sabbpeOrderId) async {
    final res = await _post<Map<String, dynamic>>(
      '/api/v1/cfpg/payment/status',
      {'sabbpeOrderId': sabbpeOrderId},
    );
    return PaymentStatusResponse.fromJson(res);
  }

  Future<PaymentStatusResponse> checkDiamondPaymentStatus(String sabbpeOrderId) async {
    final res = await _post<Map<String, dynamic>>(
      '/api/v1/diamond/cfpg/payment/status',
      {'sabbpeOrderId': sabbpeOrderId},
    );
    return PaymentStatusResponse.fromJson(res);
  }

  String generateOrderId(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = (DateTime.now().microsecondsSinceEpoch % 1000000).toRadixString(36);
    return 'KARATLY-$prefix-$ts$rand'.toUpperCase();
  }
}
