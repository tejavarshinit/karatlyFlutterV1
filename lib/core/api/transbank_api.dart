import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import '../utils/constants.dart';
import 'config.dart';

class TransbankApi {
  final Dio _dio;

  TransbankApi(this._dio);

  Map<String, dynamic> _getJson(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    final text = data?.toString() ?? '';
    try {
      return text.isNotEmpty ? jsonDecode(text) : {};
    } catch (_) {
      return {'message': 'Invalid server response'};
    }
  }

  String? _extractErrorMessage(Map<String, dynamic> data) {
    final raw = data['message']?.toString();
    if (raw == null || raw.isEmpty) return null;

    if (raw.startsWith('{')) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) {
          final errors = parsed['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstErrors = errors.values.first;
            if (firstErrors is List && firstErrors.isNotEmpty) {
              final firstError = firstErrors.first;
              if (firstError is Map && firstError['message'] != null) {
                return firstError['message'].toString();
              }
            }
          }
          if (parsed['message'] != null) return parsed['message'].toString();
        }
      } catch (_) {}
      return raw;
    }

    return raw;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final token = LocalStorageService.getToken() ?? '';
      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}$path',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          receiveTimeout: AppConstants.ocrTimeout,
        ),
      );

      if (res.statusCode == 401) {
        await LocalStorageService.clearAuthSession();
        return {'ok': false, 'message': 'Session expired. Please login again.'};
      }

      final json = _getJson(res);

      if (res.statusCode != null && res.statusCode! >= 400) {
        final cleanMsg = _extractErrorMessage(json);
        if (cleanMsg != null) {
          return {'ok': false, 'message': cleanMsg, 'statusCode': res.statusCode};
        }
      }

      return json;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {'ok': false, 'message': 'Request timed out. Please check your connection and try again.'};
      }
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  // ── PAN Validation ──
  bool _isPanSuccessResponse(Map<String, dynamic> data) {
    final result = data['result'] as Map<String, dynamic>?;
    final status = data['status'] ?? result?['status'];
    final message = (data['message']?.toString() ?? result?['message']?.toString() ?? '').toLowerCase();
    return status == 1 || status == '1' || message == 'success' || data['ok'] == true || data['isValid'] == true;
  }

  Future<Map<String, dynamic>> transbankValidatePan({
    required String panNumber,
    required String name,
    required String mobile,
  }) async {
    final data = await _post('/api/v1/kyc/pan/validate', {
      'name': name,
      'mobile': mobile,
      'consent_text': 'We confirm obtaining valid customer consent to access/process their name/mobile data. Consent remains valid, informed, and unwithdrawn.',
      'consent': 'Y',
      'panNumber': panNumber,
    });

    final verified = _isPanSuccessResponse(data);
    return {
      ...data,
      'ok': verified,
      'isValid': verified,
      'message': data['message']?.toString() ?? (verified ? 'Success' : 'PAN could not be verified.'),
      'raw': data,
    };
  }

  // ── Aadhaar OTP ──
  bool _isAadhaarSuccessResponse(Map<String, dynamic> data) {
    final raw = data['raw'] as Map<String, dynamic>?;
    final rawStatus = (raw?['status']?.toString() ?? '').toLowerCase();
    final rawStatusCode = int.tryParse(raw?['serviceStatusCode']?.toString() ?? raw?['statusCode']?.toString() ?? '0') ?? 0;
    if (rawStatus == 'error' || (rawStatusCode >= 400 && rawStatusCode < 600)) return false;
    final payload = data['payload'] as Map<String, dynamic>?;
    final payloadMessage = (payload?['message']?.toString() ?? '').toLowerCase();
    if (payloadMessage.contains('error') || payloadMessage.contains('invalid') || payloadMessage.contains('fail')) return false;
    return data['ok'] == true ||
        data['success'] == true ||
        ((data['data'] as Map<String, dynamic>?)?['success'] == true) ||
        (data['statusCode']?.toString().startsWith('2') ?? false) ||
        (data['status']?.toString().toLowerCase() == 'ok');
  }

  Future<Map<String, dynamic>> transbankAadhaarGenerateOtp(String aadhaarNumber) async {
    final data = await _post('/api/v1/kyc/aadhaar/generate-otp', {'aadhaarNumber': aadhaarNumber});
    final payload = data['payload'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    final resultData = result?['data'] as Map<String, dynamic>?;
    final payloadData = payload?['data'] as Map<String, dynamic>?;
    final dataObj = data['data'] as Map<String, dynamic>?;
    final sessionId = (dataObj?['sessionId']?.toString() ?? data['sessionId']?.toString() ?? resultData?['sessionId']?.toString() ?? payloadData?['sessionId']?.toString() ?? '').trim();
    final ok = _isAadhaarSuccessResponse(data) && sessionId.isNotEmpty;

    return {
      ...data,
      'ok': ok,
      'sessionId': sessionId,
      'message': data['message']?.toString() ?? (ok ? 'OTP sent successfully.' : 'Could not send OTP.'),
      'raw': data,
    };
  }

  Future<Map<String, dynamic>> transbankAadhaarSubmitOtp({
    required String aadhaarNumber,
    required String otp,
    required String sessionId,
    required String uniqueId,
  }) async {
    final data = await _post('/api/v1/kyc/aadhaar/submit-otp', {
      'input': {
        'referenceId': sessionId,
        'otp': otp,
        'uniqueId': uniqueId,
        'aadhaarNumber': aadhaarNumber,
      },
    });
    final ok = _isAadhaarSuccessResponse(data);
    return {
      ...data,
      'ok': ok,
      'message': data['message']?.toString() ?? (ok ? 'Aadhaar verified successfully.' : 'OTP verification failed.'),
      'raw': data,
    };
  }

  // ── Aadhaar OCR ──
  Future<Map<String, dynamic>> transbankAadhaarOcr({
    required String base64Image,
    required String uniqueId,
  }) async {
    try {
      final data = await _post('/api/v1/kyc/ocr/aadhaar', {
        'doc_front_image': base64Image,
        'doc_type': 'AADHAAR',
        'uniqueId': uniqueId,
      });
      final result = (data['result'] as Map<String, dynamic>?) ??
          (data['data'] as Map<String, dynamic>?) ??
          ((data['payload'] as Map<String, dynamic>?)?['result'] as Map<String, dynamic>?) ??
          {};

      final name = (result['name_on_card']?.toString() ??
              result['name']?.toString() ??
              result['full_name']?.toString() ??
              data['name_on_card']?.toString() ??
              data['name']?.toString() ?? '')
          .trim();

      final cardNumber = (result['card_number']?.toString() ??
              result['aadhaarNumber']?.toString() ??
              result['aadhaar_number']?.toString() ??
              data['card_number']?.toString() ??
              data['aadhaarNumber']?.toString() ?? '')
          .trim();

      final dob = (result['date_of_birth']?.toString() ??
              result['dob']?.toString() ??
              data['date_of_birth']?.toString() ?? '')
          .trim();

      final gender = (result['gender']?.toString() ?? data['gender']?.toString() ?? '').trim();

      final status = data['status'];
      final message = (data['message']?.toString() ?? '').toLowerCase();
      final ok = status == 1 || status == '1' || message == 'success' || data['ok'] == true;

      return {
        'ok': ok,
        'name': name.isNotEmpty ? name : null,
        'cardNumber': cardNumber.isNotEmpty ? cardNumber : null,
        'dateOfBirth': dob.isNotEmpty ? dob : null,
        'gender': gender.isNotEmpty ? gender : null,
        'message': data['message']?.toString() ?? (ok ? 'Aadhaar verified via OCR.' : 'OCR failed. Please try again with a clearer photo.'),
        'raw': data,
      };
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        return {'ok': false, 'message': 'OCR request timed out. Please try again.'};
      }
      return {'ok': false, 'message': 'Network error during OCR. Please try again.'};
    }
  }

  // ── Bank Validation ──
  bool _isBankValidationSuccessResponse(Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>?;
    final result = data['result'] as Map<String, dynamic>?;
    final status = data['status'] ?? result?['status'];
    final statusText = (status?.toString() ?? '').toLowerCase();
    final statusCode = (payload?['statusCode']?.toString() ?? data['statusCode']?.toString() ?? '').toUpperCase();
    final message = (payload?['message']?.toString() ?? data['message']?.toString() ?? result?['message']?.toString() ?? '').toLowerCase();
    final verificationStatus = (result?['verificationStatus']?.toString() ?? result?['accountStatus']?.toString() ?? data['acValidationStatus']?.toString() ?? '').toLowerCase();

    if (statusCode == 'TB009' ||
        verificationStatus.contains('unsupport') ||
        verificationStatus.contains('invalid') ||
        RegExp(r'invalid|unsupported|unsupportive|failed|failure|rejected', caseSensitive: false).hasMatch(message)) {
      return false;
    }

    return data['isValid'] == true ||
        status == 1 ||
        status == '1' ||
        statusText == 'success' ||
        statusText == 'accepted' ||
        statusCode.startsWith('2') ||
        verificationStatus == 'verified' ||
        verificationStatus == 'success' ||
        verificationStatus == 'account_valid' ||
        RegExp(r'success|verified', caseSensitive: false).hasMatch(message);
  }

  Future<Map<String, dynamic>> transbankValidateBankAccount({
    required String accountName,
    required String accountNumber,
    required String ifscCode,
    String? merchantId,
    String? uniqueId,
  }) async {
    final data = await _post('/api/v1/kyc/bank/validate', {
      'custName': accountName,
      'custAcctNo': accountNumber,
      'custIfsc': ifscCode,
      'merchantId': merchantId ?? ApiConfig.defaultMerchantId,
      'uniqueId': uniqueId,
    });

    final verified = _isBankValidationSuccessResponse(data);
    final payload = data['payload'] as Map<String, dynamic>?;
    final message = payload?['message']?.toString() ?? data['message']?.toString() ?? '';

    return {
      ...data,
      'ok': verified,
      'isValid': verified,
      'bankVerified': verified,
      'message': verified ? 'Bank account verified successfully.' : message,
      'raw': data,
    };
  }

  // ── PAN OCR ──
  Future<Map<String, dynamic>> transbankPanOcr({
    required dynamic file,
    required String uniqueId,
    String? mobile,
  }) async {
    try {
      final token = LocalStorageService.getToken() ?? '';
      final formData = FormData.fromMap({
        'doc_front_image': file,
        'doc_type': 'PAN',
        'uniqueId': uniqueId,
        if (mobile != null) 'mobile': mobile,
      });

      final res = await _dio.post(
        '${ApiConfig.augmontBaseUrl}/api/v1/kyc/ocr',
        data: formData,
        options: Options(
          headers: {
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          receiveTimeout: AppConstants.ocrTimeout,
        ),
      );

      if (res.statusCode == 401) {
        return {'ok': false, 'message': 'Session expired. Please login again.'};
      }

      final data = _getJson(res);
      final result = (data['result'] as Map<String, dynamic>?) ??
          (data['data'] as Map<String, dynamic>?) ??
          ((data['payload'] as Map<String, dynamic>?)?['result'] as Map<String, dynamic>?) ??
          {};

      final panNumber = (result['panNumber']?.toString() ??
              result['pan_number']?.toString() ??
              result['pan']?.toString() ??
              result['idNumber']?.toString() ??
              result['card_number']?.toString() ??
              data['panNumber']?.toString() ??
              data['card_number']?.toString() ??
              '')
          .toUpperCase()
          .trim();

      final name = (result['name']?.toString() ??
              result['full_name']?.toString() ??
              result['fullName']?.toString() ??
              result['nameOnCard']?.toString() ??
              result['name_on_card']?.toString() ??
              data['name']?.toString() ??
              data['name_on_card']?.toString() ??
              '')
          .trim();

      final rawDob = (result['dateOfBirth']?.toString() ??
              result['dob']?.toString() ??
              result['date_of_birth']?.toString() ??
              data['dateOfBirth']?.toString() ??
              data['date_of_birth']?.toString() ??
              '')
          .trim();

      String? dateOfBirth;
      if (rawDob.isNotEmpty) {
        final ddmmyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(rawDob);
        if (ddmmyyyy != null) {
          dateOfBirth = '${ddmmyyyy.group(3)}-${ddmmyyyy.group(2)}-${ddmmyyyy.group(1)}';
        } else {
          dateOfBirth = rawDob;
        }
      }

      final ok = data['ok'] == true ||
          (data['status']?.toString().toLowerCase() == 'success') ||
          (data['status']?.toString() == '1') ||
          RegExp(r'success', caseSensitive: false).hasMatch(data['message']?.toString() ?? '') ||
          (panNumber.isNotEmpty && RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(panNumber));

      return {
        'ok': ok,
        'panNumber': panNumber.isNotEmpty ? panNumber : null,
        'name': name.isNotEmpty ? name : null,
        'dateOfBirth': dateOfBirth,
        'message': data['message']?.toString() ?? (ok ? 'PAN verified via OCR.' : 'Could not verify PAN from image.'),
        'raw': data,
      };
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        return {'ok': false, 'message': 'OCR request timed out. Please try again.'};
      }
      return {'ok': false, 'message': 'Network error during OCR. Please try again.'};
    }
  }
}
