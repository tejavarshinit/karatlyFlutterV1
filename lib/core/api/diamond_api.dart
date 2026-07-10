import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'config.dart';

class DiamondApi {
  final Dio _dio;

  DiamondApi(this._dio);

  static const _prefix = '/api/v1/diamond';

  String get _diamondClientId => LocalStorageService.getDiamondClientId() ?? '';

  Map<String, String> _headers({bool includeClientId = false}) => {
    'Content-Type': 'application/json',
    if (includeClientId && _diamondClientId.isNotEmpty) 'x-client-id': _diamondClientId,
  };

  Future<Map<String, dynamic>> _diamondPost(
    String path,
    Map<String, dynamic> body, [
    String fallbackMessage = 'Diamond API request failed',
    bool includeClientIdHeader = false,
    bool includeClientIdBody = false,
  ]) async {
    try {
      final clientId = includeClientIdBody ? _diamondClientId : '';
      final finalBody = includeClientIdBody && clientId.isNotEmpty ? {'clientId': clientId, ...body} : body;

      final res = await _dio.post(
        '${ApiConfig.diamondBaseUrl}$_prefix$path',
        data: finalBody,
        options: Options(headers: _headers(includeClientId: includeClientIdHeader)),
      );

      final data = res.data is String ? jsonDecode(res.data as String) : res.data as Map<String, dynamic>;
      final msg = (data['message']?.toString() ?? '').toLowerCase();
      final isOk = (res.statusCode ?? 500) < 400 &&
          (msg.contains('success') || data['message'] == null || (res.statusCode ?? 500) < 400);

      if (!isOk) {
        return {'ok': false, 'message': data['message']?.toString() ?? fallbackMessage, 'data': data, 'raw': data};
      }
      return {'ok': true, 'data': data, 'raw': data};
    } catch (error) {
      return {'ok': false, 'message': error is Exception ? error.toString() : fallbackMessage};
    }
  }

  // ── Products ──
  static const int pageSize = 10;

  Map<String, int> getPageRange(int page) => {
    'from': page * pageSize,
    'to': page * pageSize + pageSize,
  };

  Future<Map<String, dynamic>> fetchDiamondProducts({
    int from = 0,
    int to = 10,
    String? shape,
    String? color,
    String? clarity,
    String? cut,
    String? polish,
    String? symmetry,
    String? fluorescence,
    String? certificate,
    double? minCarat,
    double? maxCarat,
    double? minFinalPrice,
    double? maxFinalPrice,
    bool hasImage = true,
    bool hasVideo = true,
    bool? hasBuyback,
    String? sortBy,
    String? sortOrder,
    double? minLength,
    double? maxLength,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    double? minLwRatio,
    double? maxLwRatio,
    double? minCrownAngle,
    double? maxCrownAngle,
    double? minTablePercent,
    double? maxTablePercent,
    double? minPavilionAngle,
    double? maxPavilionAngle,
    double? minPriceUsd,
    double? maxPriceUsd,
  }) async {
    return _diamondPost('/products', {
      'from': from,
      'to': to,
      'certificate': certificate,
      'hasImage': hasImage,
      'hasVideo': hasVideo,
      'hasBuyback': hasBuyback,
      'shape': shape,
      'color': color,
      'clarity': clarity,
      'cut': cut,
      'polish': polish,
      'symmetry': symmetry,
      'fluorescence': fluorescence,
      'minCarat': minCarat,
      'maxCarat': maxCarat,
      'minFinalPrice': minFinalPrice,
      'maxFinalPrice': maxFinalPrice,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'minLength': minLength,
      'maxLength': maxLength,
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'minLwRatio': minLwRatio,
      'maxLwRatio': maxLwRatio,
      'minCrownAngle': minCrownAngle,
      'maxCrownAngle': maxCrownAngle,
      'minTablePercent': minTablePercent,
      'maxTablePercent': maxTablePercent,
      'minPavilionAngle': minPavilionAngle,
      'maxPavilionAngle': maxPavilionAngle,
      'minPriceUsd': minPriceUsd,
      'maxPriceUsd': maxPriceUsd,
      'count': true,
    }, 'Failed to fetch diamond products');
  }

  // ── Cart ──
  Future<Map<String, dynamic>> addToDiamondCart(String productId) async {
    return _diamondPost('/cart/add', {
      'clientId': _diamondClientId,
      'cartProducts': [
        {
          'lineType': 'LGD',
          'productId': productId,
          'meleeInventoryId': '',
          'unit': 'pc',
          'quantity': 1,
        },
      ],
    }, 'Failed to add diamond to cart', false, true);
  }

  Future<Map<String, dynamic>> fetchDiamondCart() async {
    return _diamondPost('/cart', {
      'clientId': _diamondClientId,
    }, 'Failed to fetch diamond cart');
  }

  Future<Map<String, dynamic>> removeDiamondCartItem(String cartItemId) async {
    return _diamondPost('/cart/delete', {
      'id': cartItemId,
      'clientId': _diamondClientId,
    }, 'Failed to remove diamond from cart', false, true);
  }

  // ── Payment ──
  Future<Map<String, dynamic>> initiateDiamondPayment({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    return _diamondPost('/payment', {
      'clientId': _diamondClientId,
      'totalAmount': totalAmount,
      'items': items,
    }, 'Failed to initiate diamond payment');
  }

  Future<Map<String, dynamic>> fetchDiamondPaymentDetails(String orderReference) async {
    return _diamondPost('/payment/details', {
      'orderReference': orderReference,
    }, 'Failed to fetch payment details');
  }

  // ── Orders ──
  Future<Map<String, dynamic>> fetchDiamondOrders() async {
    return _diamondPost('/orders/history', {
      'clientId': _diamondClientId,
    }, 'Failed to fetch diamond orders');
  }

  // ── Payment Status ──
  Future<Map<String, dynamic>> checkDiamondPaymentStatus(String sabbpeOrderId) async {
    return _diamondPost('/cfpg/payment/status', {
      'sabbpeOrderId': sabbpeOrderId,
    }, 'Failed to check diamond payment status');
  }
}
