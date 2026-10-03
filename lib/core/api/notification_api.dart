import 'package:dio/dio.dart';
import '../services/push_notification_service.dart' show pushLog;
import '../storage/local_storage.dart';
import 'config.dart';

/// Backend device-token registration for Firebase Cloud Messaging.
///
/// POST /api/v1/notification/device-token
///   { deviceToken, deviceType: ANDROID | IOS, uniqueId }
/// The backend resolves client_id from client_profile.provider_client_reference
/// and upserts user_device_tokens (same token → update, no duplicate).
class NotificationApi {
  final Dio _dio;

  NotificationApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Content-Type': 'application/json'},
              validateStatus: (_) => true,
            ));

  String get _baseUrl => ApiConfig.notificationBaseUrl;

  Future<Map<String, dynamic>> registerDeviceToken({
    required String deviceToken,
    required String deviceType,
    required String uniqueId,
  }) async {
    final token = LocalStorageService.getToken() ?? '';
    final url = '$_baseUrl/api/v1/notification/device-token';
    pushLog('REGISTER request -> POST $url | deviceType=$deviceType uniqueId=$uniqueId');
    try {
      final res = await _dio.post(
        url,
        data: {
          'deviceToken': deviceToken,
          'deviceType': deviceType,
          'uniqueId': uniqueId,
        },
        options: Options(headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        }),
      );
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      final ok = res.statusCode == 200 && data['success'] == true;
      pushLog('REGISTER response <- ${res.statusCode} ok=$ok body=${res.data}');
      return {...data, 'ok': ok, 'statusCode': res.statusCode};
    } on DioException catch (e) {
      pushLog('REGISTER network error: ${e.type.name} ${e.message}');
      return {'ok': false, 'message': e.message ?? 'Network error'};
    }
  }
}
