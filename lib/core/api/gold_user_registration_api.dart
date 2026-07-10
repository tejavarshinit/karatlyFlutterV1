import 'dart:convert';
import 'package:dio/dio.dart';
import 'config.dart';

class GoldUserRegistrationApi {
  final Dio _dio;

  GoldUserRegistrationApi(this._dio);

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
    final responseBody = payload?['responseBody']?.toString();
    if (responseBody != null && responseBody.isNotEmpty) {
      try {
        final parsed = jsonDecode(responseBody);
        if (parsed is Map && parsed['message'] != null) return parsed['message'].toString();
      } catch (_) {}
      return responseBody;
    }
    return payload?['message']?.toString() ?? data['message']?.toString() ?? fallback;
  }

  List<dynamic> _extractList(Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    final list = result?['data'] ?? result?['records'] ?? result ?? data['data'] ?? [];
    return list is List ? list : [];
  }

  Map<String, String> _normalizeMasterItem(dynamic item) {
    final map = item as Map<String, dynamic>;
    return {
      'id': map['id']?.toString() ?? map['stateId']?.toString() ?? map['cityId']?.toString() ?? '',
      'name': map['name']?.toString() ?? map['stateName']?.toString() ?? map['cityName']?.toString() ?? '',
    };
  }

  Future<Map<String, dynamic>> _requestRegistrationApi(
    String path,
    Map<String, dynamic> body,
    String fallbackMessage,
  ) async {
    try {
      final res = await _dio.post(
        '${ApiConfig.goldBaseUrl}$path',
        data: {'merchantId': ApiConfig.defaultMerchantId, ...body},
      );
      final data = _getJson(res);
      if ((res.statusCode ?? 500) >= 400 || data['status'] == 'error') {
        return {'ok': false, 'message': _extractBackendMessage(data, fallbackMessage), 'raw': data};
      }
      return {'ok': true, 'data': data, 'raw': data};
    } catch (error) {
      return {'ok': false, 'message': fallbackMessage};
    }
  }

  Future<Map<String, dynamic>> fetchStates([String name = '']) async {
    final response = await _requestRegistrationApi(
      '/api/v1/master/states',
      {'page': 1, 'count': 100, 'name': name.trim()},
      'Failed to fetch states',
    );
    if (!response['ok']) return {...response, 'states': []};
    return {
      'ok': true,
      'states': _extractList(response['data'] as Map<String, dynamic>)
          .map(_normalizeMasterItem)
          .where((item) => item['id']!.isNotEmpty && item['name']!.isNotEmpty)
          .toList(),
    };
  }

  Future<Map<String, dynamic>> fetchCities(String stateId, [String name = '']) async {
    final response = await _requestRegistrationApi(
      '/api/v1/master/cities',
      {'stateId': stateId, 'page': 1, 'count': 100, 'name': name.trim()},
      'Failed to fetch cities',
    );
    if (!response['ok']) return {...response, 'cities': []};
    return {
      'ok': true,
      'cities': _extractList(response['data'] as Map<String, dynamic>)
          .map(_normalizeMasterItem)
          .where((item) => item['id']!.isNotEmpty && item['name']!.isNotEmpty)
          .toList(),
    };
  }

  Future<Map<String, dynamic>> createGoldUser(Map<String, dynamic> request) async {
    final response = await _requestRegistrationApi(
      '/api/v1/users/create',
      {'request': request},
      'Failed to create user',
    );
    if (!response['ok']) return response;
    final payload = (response['data'] as Map<String, dynamic>?)?['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    return {
      'ok': true,
      'data': result?['data'] ?? result ?? (response['data'] as Map<String, dynamic>?)?['data'] ?? {},
      'message': payload?['message']?.toString() ?? 'User created successfully',
    };
  }
}
