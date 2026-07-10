import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'config.dart';

class DemoApi {
  final Dio _dio;

  DemoApi(this._dio);

  static const String demoPhone = '9999999999';
  static const String demoUniqueId = 'DEMO-AUG-QA-001';
  static const String demoOtp = '000000';

  static bool isDemoPhone(String phone) {
    return phone.replaceAll(RegExp(r'\s'), '') == demoPhone;
  }

  Future<Map<String, dynamic>> demoLogin({
    required String phone,
    required String email,
    String name = 'QA Tester',
  }) async {
    try {
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/demo/login',
        data: {'phone': phone, 'email': email, 'name': name},
      );
      final data = res.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Demo login failed');
      }

      final payload = data['payload'] as Map<String, dynamic>;
      final token = payload['token']?.toString() ?? '';
      final user = payload['user'] as Map<String, dynamic>;

      await LocalStorageService.setAuthSession(token);
      await LocalStorageService.setDemoUser(true);
      await LocalStorageService.setUserPhone(user['phone']?.toString() ?? '');
      await LocalStorageService.setUserEmail(user['email']?.toString() ?? '');
      await LocalStorageService.setUserName(user['name']?.toString() ?? '');
      await LocalStorageService.setUserUniqueId(user['uniqueId']?.toString() ?? '');

      return {'token': token, 'user': user};
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDemoStatus() async {
    try {
      final res = await _dio.get('${ApiConfig.augmontBaseUrl}/api/v1/demo/status');
      return res.data as Map<String, dynamic>;
    } catch (error) {
      return {'error': error.toString()};
    }
  }

  Future<Map<String, dynamic>> setupDemoUser(String secret) async {
    try {
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/demo/setup',
        options: Options(headers: {'X-Demo-Secret': secret}),
      );
      return res.data as Map<String, dynamic>;
    } catch (error) {
      return {'error': error.toString()};
    }
  }

  static Future<void> clearDemoSession() async {
    await LocalStorageService.clearAuthSession();
    await LocalStorageService.setDemoUser(false);
  }

  static bool isCurrentSessionDemo() {
    return LocalStorageService.isDemoUser();
  }
}
