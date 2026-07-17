import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;
  static const _secureStorage = FlutterSecureStorage();

  static const _keyToken = 'token';
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserProfile = 'userProfile';
  static const _keyGoldBalance = 'goldBalance';
  static const _keySilverBalance = 'silverBalance';
  static const _keyGoldPrice = 'goldPrice';
  static const _keyAugmontUser = 'augmontUser';
  static const _keyAugmontOrderReferences = 'augmontOrderReferences';
  static const _keyPrimaryBank = 'primaryBank';
  static const _keyPrimaryBankId = 'primaryBankId';
  static const _keyProfilePhoto = 'profilePhoto';
  static const _keyUserPan = 'userPan';
  static const _keyUserState = 'userState';
  static const _keyIsDemoUser = 'isDemoUser';
  static const _keyUserPhone = 'userPhone';
  static const _keyUserEmail = 'userEmail';
  static const _keyUserName = 'userName';
  static const _keyUserUniqueId = 'userUniqueId';
  static const _keyDiamondClientId = 'diamondClientId';
  static const _keyDiamondPaymentContext = 'diamondPaymentContext';
  static const _keyRedeemResult = 'redeemResult';
  static const _keyMobilePaymentResult = 'mobilePaymentResult';
  static const _keyHasSeenSplash = 'hasSeenSplash';
  static const _keyPendingRegistrationProfile = 'pendingRegistrationProfile';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) throw Exception('LocalStorageService not initialized');
    return _prefs!;
  }

  // Token
  static String? getToken() => _instance.getString(_keyToken);
  static Future<void> setToken(String token) async {
    await _instance.setString(_keyToken, token);
    await _secureStorage.write(key: _keyToken, value: token);
  }

  static Future<String?> getSecureToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  // Auth state
  static bool isLoggedIn() => _instance.getBool(_keyIsLoggedIn) ?? false;
  static Future<void> setLoggedIn(bool value) async {
    await _instance.setBool(_keyIsLoggedIn, value);
  }

  // Splash
  static bool hasSeenSplash() => _instance.getBool(_keyHasSeenSplash) ?? false;
  static Future<void> setHasSeenSplash(bool value) async {
    await _instance.setBool(_keyHasSeenSplash, value);
  }

  // User profile
  static Map<String, dynamic>? getUserProfile() {
    final raw = _instance.getString(_keyUserProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      try {
        final decoded = jsonDecode(Uri.decodeComponent(raw));
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
      return null;
    }
  }

  static Future<void> setUserProfile(Map<String, dynamic> profile) async {
    await _instance.setString(_keyUserProfile, jsonEncode(profile));
  }

  // Pending registration profile
  static Map<String, dynamic>? getPendingRegistrationProfile() {
    final raw = _instance.getString(_keyPendingRegistrationProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setPendingRegistrationProfile(Map<String, dynamic>? profile) async {
    if (profile == null) {
      await _instance.remove(_keyPendingRegistrationProfile);
    } else {
      await _instance.setString(_keyPendingRegistrationProfile, jsonEncode(profile));
    }
  }

  // Gold/Silver balance
  static double getGoldBalance() => _instance.getDouble(_keyGoldBalance) ?? 0.0;
  static Future<void> setGoldBalance(double value) async {
    await _instance.setDouble(_keyGoldBalance, value);
  }

  static double getSilverBalance() => _instance.getDouble(_keySilverBalance) ?? 0.0;
  static Future<void> setSilverBalance(double value) async {
    await _instance.setDouble(_keySilverBalance, value);
  }

  static double getGoldPrice() => _instance.getDouble(_keyGoldPrice) ?? 0.0;
  static Future<void> setGoldPrice(double value) async {
    await _instance.setDouble(_keyGoldPrice, value);
  }

  // Augmont user
  static String? getAugmontUser() => _instance.getString(_keyAugmontUser);
  static Future<void> setAugmontUser(String value) async {
    await _instance.setString(_keyAugmontUser, value);
  }

  // Order references
  static String? getAugmontOrderReferences() => _instance.getString(_keyAugmontOrderReferences);
  static Future<void> setAugmontOrderReferences(String value) async {
    await _instance.setString(_keyAugmontOrderReferences, value);
  }

  // Primary bank
  static String? getPrimaryBank() => _instance.getString(_keyPrimaryBank);
  static Future<void> setPrimaryBank(String value) async {
    await _instance.setString(_keyPrimaryBank, value);
  }

  static String? getPrimaryBankId() => _instance.getString(_keyPrimaryBankId);
  static Future<void> setPrimaryBankId(String value) async {
    await _instance.setString(_keyPrimaryBankId, value);
  }

  // Profile photo
  static String? getProfilePhoto() => _instance.getString(_keyProfilePhoto);
  static Future<void> setProfilePhoto(String value) async {
    await _instance.setString(_keyProfilePhoto, value);
  }

  // User PAN
  static String? getUserPan() => _instance.getString(_keyUserPan);
  static Future<void> setUserPan(String value) async {
    await _instance.setString(_keyUserPan, value);
  }

  // User State
  static String? getUserState() => _instance.getString(_keyUserState);
  static Future<void> setUserState(String value) async {
    await _instance.setString(_keyUserState, value);
  }

  // Demo user
  static bool isDemoUser() => _instance.getBool(_keyIsDemoUser) ?? false;
  static Future<void> setDemoUser(bool value) async {
    await _instance.setBool(_keyIsDemoUser, value);
  }

  static String? getUserPhone() => _instance.getString(_keyUserPhone);
  static Future<void> setUserPhone(String value) async {
    await _instance.setString(_keyUserPhone, value);
  }

  static String? getUserEmail() => _instance.getString(_keyUserEmail);
  static Future<void> setUserEmail(String value) async {
    await _instance.setString(_keyUserEmail, value);
  }

  static String? getUserName() => _instance.getString(_keyUserName);
  static Future<void> setUserName(String value) async {
    await _instance.setString(_keyUserName, value);
  }

  static String? getUserUniqueId() => _instance.getString(_keyUserUniqueId);
  static Future<void> setUserUniqueId(String value) async {
    await _instance.setString(_keyUserUniqueId, value);
  }

  // Diamond client ID
  static String? getDiamondClientId() => _instance.getString(_keyDiamondClientId);
  static Future<void> setDiamondClientId(String value) async {
    await _instance.setString(_keyDiamondClientId, value);
  }

  // Diamond payment context
  static String? getDiamondPaymentContext() => _instance.getString(_keyDiamondPaymentContext);
  static Future<void> setDiamondPaymentContext(String value) async {
    await _instance.setString(_keyDiamondPaymentContext, value);
  }
  static Future<void> clearDiamondPaymentContext() async {
    await _instance.remove(_keyDiamondPaymentContext);
  }

  // Redeem result
  static String? getRedeemResult() => _instance.getString(_keyRedeemResult);
  static Future<void> setRedeemResult(String value) async {
    await _instance.setString(_keyRedeemResult, value);
  }
  static Future<void> clearRedeemResult() async {
    await _instance.remove(_keyRedeemResult);
  }

  // Mobile payment result (normalized verifyPaymentDetails response)
  static String? getMobilePaymentResult() => _instance.getString(_keyMobilePaymentResult);
  static Future<void> setMobilePaymentResult(String value) async {
    await _instance.setString(_keyMobilePaymentResult, value);
  }
  static Future<void> clearMobilePaymentResult() async {
    await _instance.remove(_keyMobilePaymentResult);
  }

  // Auth session
  static Future<void> setAuthSession(String token) async {
    await setToken(token);
    await setLoggedIn(true);
    await _instance.remove(_keyGoldBalance);
    await _instance.remove(_keyGoldPrice);
    await _instance.remove(_keyProfilePhoto);
    await _instance.remove(_keyAugmontUser);
  }

  static Future<void> clearAuthSession() async {
    await _instance.remove(_keyToken);
    await _instance.remove(_keyIsLoggedIn);
    await _instance.remove(_keyUserProfile);
    await _instance.remove(_keyGoldBalance);
    await _instance.remove(_keyPrimaryBank);
    await _instance.remove(_keyPrimaryBankId);
    await _instance.remove(_keyProfilePhoto);
    await _instance.remove(_keyAugmontUser);
    await _instance.remove(_keyAugmontOrderReferences);
    await _instance.remove(_keyUserPan);
    await _instance.remove(_keyUserState);
    await _instance.remove(_keyIsDemoUser);
    await _instance.remove(_keyUserPhone);
    await _instance.remove(_keyUserEmail);
    await _instance.remove(_keyUserName);
    await _instance.remove(_keyUserUniqueId);
    await _instance.remove(_keyDiamondClientId);
    await _secureStorage.delete(key: _keyToken);
  }

  static bool isAuthenticated() {
    return isLoggedIn() && (getToken()?.isNotEmpty ?? false);
  }
}
