import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import '../utils/unique_id.dart';
import 'config.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  static Map<String, dynamic> _getJson(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final text = data.trim();
      if (text.isEmpty) return {};
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        return {'data': decoded};
      } catch (_) {
        return {'success': false, 'message': text};
      }
    }
    if (data == null) return {};
    return {'data': data};
  }

  static bool _isSuccess(Map<String, dynamic> data) {
    return data['success'] == true ||
        data['valid'] == true ||
        data['token'] != null ||
        (data['payload'] as Map<String, dynamic>?)?['token'] != null;
  }

  static Map<String, dynamic> _normalizeError(dynamic error, String fallback) {
    final msg = error is Exception ? error.toString() : fallback;
    return {'success': false, 'ok': false, 'message': msg};
  }

  static Map<String, dynamic> _extractProfileFromAuthResponse(Map<String, dynamic> data) {
    final user = (data['userInfo'] as Map<String, dynamic>?) ??
        (data['user'] as Map<String, dynamic>?) ??
        (data['payload'] as Map<String, dynamic>?);
    final userObj = user ?? {};
    return {
      'fullName': userObj['fullName']?.toString() ?? userObj['name']?.toString() ?? '',
      'email': userObj['email']?.toString() ?? userObj['emailId']?.toString() ?? '',
      'mobileNumber': userObj['mobileNumber']?.toString() ?? userObj['mobile']?.toString() ?? '',
      'pinCode': userObj['pinCode']?.toString() ?? userObj['pincode']?.toString() ?? '',
      'dateOfBirth': userObj['dateOfBirth']?.toString() ?? userObj['dob']?.toString() ?? '',
      'uniqueId': userObj['augmontUniqueId']?.toString() ?? userObj['uniqueId']?.toString() ?? '',
      'partnerUserId': userObj['partnerUserId']?.toString() ?? '',
      'panVerified': userObj['panVerified'] == true,
      'aadhaarVerified': userObj['aadhaarVerified'] == true,
      'bankVerified': userObj['bankVerified'] == true,
      'kycStatus': userObj['kycStatus']?.toString() ?? '',
      'profilePhoto': userObj['profilePhoto']?.toString(),
    };
  }

  String _formatDateOfBirthForAuth(String value) {
    final dateValue = value.trim();
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dateValue);
    if (isoMatch != null) {
      final year = isoMatch.group(1);
      final month = isoMatch.group(2);
      final day = isoMatch.group(3);
      return '$day-$month-$year';
    }
    return dateValue;
  }

  Future<Map<String, dynamic>> sendOtp({
    required String mobileNumber,
    String email = '',
    String? fullName,
    String type = 'login',
  }) async {
    try {
      final endpoint = type == 'register'
          ? '/auth/register/send-otp'
          : '/auth/login/send-otp';

      final body = type == 'register'
          ? {'mobileNumber': mobileNumber, 'email': email, 'emailId': email, 'fullName': fullName, 'userName': fullName}
          : {'mobileNumber': mobileNumber, if (email.isNotEmpty) 'email': email};

      final res = await _dio.post(
        '${ApiConfig.authBaseUrl}$endpoint',
        data: body,
      );

      final data = _getJson(res);
      final httpOk = res.statusCode != null && res.statusCode! < 400;
      final responseSucceeded = httpOk &&
          (data['success'] == true || data['ok'] == true || data['status'] == 'success');

      return {
        'httpOk': httpOk,
        ...data,
        'ok': responseSucceeded,
        'success': responseSucceeded,
      };
    } catch (error) {
      return _normalizeError(error, 'Unable to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
    String type = 'login',
    String email = '',
    String? fullName,
    String? dateOfBirth,
  }) async {
    try {
      final endpoint = type == 'register'
          ? '/auth/register/verify-otp'
          : '/auth/login/verify-otp';

      final body = type == 'register'
          ? {
              'fullName': fullName,
              'email': email,
              'mobileNumber': mobileNumber,
              'otp': otp,
              'dateOfBirth': _formatDateOfBirthForAuth(dateOfBirth ?? ''),
            }
          : {'mobileNumber': mobileNumber, 'otp': otp, if (email.isNotEmpty) 'email': email};

      final res = await _dio.post(
        '${ApiConfig.authBaseUrl}$endpoint',
        data: body,
      );

      final data = _getJson(res);

      if (res.statusCode == 403) {
        final msg = (data['message']?.toString() ?? data['payload']?['message']?.toString() ?? '').toLowerCase();
        final is24hBlock = msg.contains('already logged in') ||
            msg.contains('24 hour') ||
            msg.contains('session') ||
            data['code'] == 'SESSION_EXISTS';
        if (is24hBlock) {
          return {
            'ok': false,
            'code': 'SESSION_EXISTS',
            'message': 'You are already logged in on another device. Only one active session is allowed per 24 hours. Please try again later or contact support.',
          };
        }
      }

      final responseSucceeded = res.statusCode != null && res.statusCode! < 400 && _isSuccess(data);
      if (!responseSucceeded) {
        return {
          'ok': false,
          'success': false,
          'code': data['code']?.toString() ?? (data['payload'] as Map<String, dynamic>?)?['code']?.toString() ?? '',
          'notRegistered': data['notRegistered'] == true,
          'alreadyRegistered': data['alreadyRegistered'] == true,
          'message': data['message']?.toString() ??
              (data['payload'] as Map<String, dynamic>?)?['message']?.toString() ??
              'OTP verification failed (${res.statusCode}).',
        };
      }

      final token = data['payload']?['token'] ??
          data['token'] ??
          data['data']?['token'] ??
          data['payload']?['result']?['token'];

      if (token == null) {
        return {'ok': false, 'message': 'No token returned from server.'};
      }

      final userInfo = (data['userInfo'] as Map<String, dynamic>?) ??
          (data['payload']?['user'] as Map<String, dynamic>?) ??
          (data['user'] as Map<String, dynamic>?) ??
          (data['data']?['user'] as Map<String, dynamic>?) ??
          {};

      final uniqueId = userInfo['augmontUniqueId']?.toString() ??
          data['payload']?['uniqueId']?.toString() ??
          data['uniqueId']?.toString() ??
          userInfo['uniqueId']?.toString();

      final partnerUserId = data['payload']?['partnerUserId']?.toString() ??
          data['partnerUserId']?.toString() ??
          userInfo['partnerUserId']?.toString() ??
          '';

      await LocalStorageService.setAuthSession(token.toString());
      await _saveUserProfile(
        fullName: userInfo['fullName']?.toString() ?? userInfo['name']?.toString() ?? userInfo['userName']?.toString() ?? '',
        email: userInfo['email']?.toString() ?? userInfo['emailId']?.toString() ?? '',
        mobileNumber: userInfo['mobile']?.toString() ?? userInfo['mobileNumber']?.toString() ?? mobileNumber,
        dateOfBirth: userInfo['dateOfBirth']?.toString() ?? dateOfBirth ?? '',
        uniqueId: uniqueId ?? '',
        partnerUserId: partnerUserId,
        panVerified: userInfo['panVerified'] == true,
        aadhaarVerified: userInfo['aadhaarVerified'] == true,
        bankVerified: userInfo['bankVerified'] == true,
        kycStatus: userInfo['kycStatus']?.toString() ?? '',
        profilePhoto: userInfo['profilePhoto']?.toString(),
      );

      final clientId = data['clientId'] ?? userInfo['clientId'];
      if (clientId != null) {
        await LocalStorageService.setDiamondClientId(clientId.toString());
      }

      return {
        'ok': true,
        'success': true,
        'token': token.toString(),
        'userInfo': userInfo,
        'uniqueId': uniqueId,
        'partnerUserId': partnerUserId,
        'message': data['message']?.toString() ??
            (data['payload'] as Map<String, dynamic>?)?['message']?.toString() ??
            '',
      };
    } catch (error) {
      return _normalizeError(error, 'Unable to verify OTP');
    }
  }

  Future<Map<String, dynamic>> validateToken() async {
    try {
      final token = LocalStorageService.getToken();
      if (token == null || token.isEmpty) {
        return {'ok': false, 'valid': false, 'message': 'No token found'};
      }

      final res = await _dio.post(
        '${ApiConfig.authBaseUrl}/auth/validate-token',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = _getJson(res);
      final backendProfile = _extractProfileFromAuthResponse(data);
      final valid = (res.statusCode != null && res.statusCode! < 400) && data['valid'] == true;

      if (valid) {
        await _saveUserProfile(
          fullName: backendProfile['fullName']?.toString() ?? '',
          email: backendProfile['email']?.toString() ?? '',
          mobileNumber: backendProfile['mobileNumber']?.toString() ?? '',
          dateOfBirth: backendProfile['dateOfBirth']?.toString() ?? '',
          uniqueId: backendProfile['uniqueId']?.toString() ?? '',
          partnerUserId: backendProfile['partnerUserId']?.toString() ?? '',
          panVerified: backendProfile['panVerified'] == true,
          aadhaarVerified: backendProfile['aadhaarVerified'] == true,
          bankVerified: backendProfile['bankVerified'] == true,
          kycStatus: backendProfile['kycStatus']?.toString() ?? '',
          profilePhoto: backendProfile['profilePhoto']?.toString(),
        );
        final clientId = data['clientId'] ?? data['userInfo']?['clientId'];
        if (clientId != null) {
          await LocalStorageService.setDiamondClientId(clientId.toString());
        }
      }

      return {
        'ok': valid,
        'valid': valid,
        'message': data['message']?.toString() ?? (valid ? 'Token is valid' : 'Invalid or expired token'),
        ...data,
        'userInfo': backendProfile,
      };
    } catch (error) {
      return _normalizeError(error, 'Unable to validate token');
    }
  }

  Future<void> _saveUserProfile({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String dateOfBirth,
    required String uniqueId,
    required String partnerUserId,
    required bool panVerified,
    required bool aadhaarVerified,
    required bool bankVerified,
    required String kycStatus,
    String? profilePhoto,
  }) async {
    final generatedUniqueId = UniqueIdHelper.buildMobileDobUniqueId(
      mobileNumber: mobileNumber,
      dateOfBirth: dateOfBirth,
    );

    final profile = {
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'dateOfBirth': dateOfBirth,
      'uniqueId': uniqueId.isNotEmpty ? uniqueId : generatedUniqueId,
      'partnerUserId': partnerUserId,
      'panVerified': panVerified,
      'aadhaarVerified': aadhaarVerified,
      'bankVerified': bankVerified,
      'kycStatus': kycStatus,
      'profilePhoto': profilePhoto,
    };

    await LocalStorageService.setUserProfile(profile);
    final resolvedUniqueId = uniqueId.isNotEmpty ? uniqueId : generatedUniqueId;
    if (resolvedUniqueId.isNotEmpty) {
      await LocalStorageService.setUserUniqueId(resolvedUniqueId);
    }
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      await LocalStorageService.setProfilePhoto(profilePhoto);
    }
  }

  static Future<void> clearAuthSession() async {
    await LocalStorageService.clearAuthSession();
  }
}
