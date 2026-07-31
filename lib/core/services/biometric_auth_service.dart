import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static const _keyJwt = 'biometric_jwt';
  static const _keyUserInfo = 'biometric_user_info';
  static const _keyBiometricEnabled = 'biometric_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    return await _storage.read(key: _keyBiometricEnabled) == 'true';
  }

  Future<void> saveLoginResult(String jwt, Map<String, dynamic> userInfo) async {
    await _storage.write(key: _keyJwt, value: jwt);
    await _storage.write(key: _keyUserInfo, value: jsonEncode(userInfo));
  }

  Future<String?> getStoredJwt() => _storage.read(key: _keyJwt);

  Future<Map<String, dynamic>?> getStoredUserInfo() async {
    final json = await _storage.read(key: _keyUserInfo);
    return json != null ? jsonDecode(json) : null;
  }

  Future<bool> enable() async {
    try {
      final auth = await _localAuth.authenticate(
        localizedReason: 'Verify identity to enable quick login',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!auth) return false;
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> login() async {
    try {
      final auth = await _localAuth.authenticate(
        localizedReason: 'Unlock to access your account',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!auth) return null;
      return await getStoredUserInfo();
    } catch (_) {
      return null;
    }
  }

  Future<void> disable() async {
    await _storage.write(key: _keyBiometricEnabled, value: 'false');
  }

  Future<void> clearAll() => _storage.deleteAll();
}
