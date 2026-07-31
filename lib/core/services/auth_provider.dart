import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../api/auth_api.dart';
import '../storage/local_storage.dart';

// ── Auth State ──
class AuthState {
  final AuthUser? user;
  final bool isAuthenticated;
  final String? phoneNumber;
  final String? email;
  final String? fullName;
  final String? profilePhoto;
  final String? dateOfBirth;
  final String authType; // 'login' | 'register'
  final String? token;
  final bool loading;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.phoneNumber,
    this.email,
    this.fullName,
    this.profilePhoto,
    this.dateOfBirth,
    this.authType = 'login',
    this.token,
    this.loading = true,
  });

  AuthState copyWith({
    AuthUser? user,
    bool? isAuthenticated,
    String? phoneNumber,
    String? email,
    String? fullName,
    String? profilePhoto,
    String? dateOfBirth,
    String? authType,
    String? token,
    bool? loading,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      authType: authType ?? this.authType,
      token: token ?? this.token,
      loading: loading ?? this.loading,
    );
  }
}

// ── Auth Notifier ──
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;

  AuthNotifier(this._authApi) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    if (_shouldSkipInitialTokenValidation()) {
      state = state.copyWith(loading: false);
      return;
    }

    if (LocalStorageService.isAuthenticated()) {
      final result = await _authApi.validateToken();
      if (result['ok'] == true) {
        final userInfo = (result['userInfo'] as Map<String, dynamic>?) ?? {};
        final user = AuthUser.fromJson(userInfo);
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          token: LocalStorageService.getToken(),
          loading: false,
          fullName: userInfo['fullName']?.toString() ?? userInfo['name']?.toString() ?? '',
          email: userInfo['email']?.toString() ?? '',
          profilePhoto: userInfo['profilePhoto']?.toString(),
        );
      } else if (result['valid'] == false) {
        await LocalStorageService.clearAuthSession();
        state = const AuthState(loading: false);
      } else {
        _syncStoredProfile();
      }
    } else {
      state = state.copyWith(loading: false);
    }
  }

  bool _shouldSkipInitialTokenValidation() {
    // In Flutter, we don't have route checking at init time like web
    return false;
  }

  void _syncStoredProfile() {
    if (!LocalStorageService.isAuthenticated()) return;
    final token = LocalStorageService.getToken();
    if (token == null) return;
    final storedProfile = LocalStorageService.getUserProfile() ?? {};
    final user = AuthUser.fromJson({...storedProfile, 'profilePhoto': null});
    state = state.copyWith(
      isAuthenticated: true,
      user: user,
      token: token,
      loading: false,
      fullName: storedProfile['fullName']?.toString() ?? '',
      email: storedProfile['email']?.toString() ?? '',
    );
  }

  Future<Map<String, dynamic>> sendOtp({
    required String mobileNumber,
    String email = '',
    String? fullName,
    String? dateOfBirth,
    String type = 'login',
  }) async {
    return _authApi.sendOtp(
      mobileNumber: mobileNumber,
      email: email,
      fullName: fullName,
      type: type,
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
    String email = '',
    String? fullName,
    String? dateOfBirth,
    String type = 'login',
  }) async {
    final response = await _authApi.verifyOtp(
      mobileNumber: mobileNumber,
      otp: otp,
      type: type,
      email: email,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
    );

    if (response['ok'] == true) {
      final userInfo = (response['userInfo'] as Map<String, dynamic>?) ?? {};
      final tokenResponse = await _authApi.validateToken().catchError((_) => <String, dynamic>{'ok': false});
      final mergedUserInfo = {
        ...userInfo,
        if (tokenResponse['ok'] == true)
          ...(tokenResponse['userInfo'] as Map<String, dynamic>? ?? {}),
      };

      final user = AuthUser.fromJson(mergedUserInfo);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        token: response['token']?.toString(),
        fullName: mergedUserInfo['fullName']?.toString() ?? mergedUserInfo['name']?.toString() ?? '',
        email: mergedUserInfo['email']?.toString() ?? '',
      );
    }

    return response;
  }

  void restoreFromToken(String token) {
    state = state.copyWith(
      isAuthenticated: true,
      token: token,
      loading: false,
    );
    _syncStoredProfile();
  }

  void logout() {
    LocalStorageService.clearAuthSession();
    state = const AuthState(loading: false);
  }

  /// Called after KYC completion to refresh user state
  Future<void> refreshAfterKyc() async {
    final result = await _authApi.validateToken();
    if (result['ok'] == true) {
      final userInfo = (result['userInfo'] as Map<String, dynamic>?) ?? {};
      final user = AuthUser.fromJson(userInfo);
      state = state.copyWith(user: user);
    }
  }
}

// ── Provider ──
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = AuthApi(ref.read(dioAugmontProvider));
  return AuthNotifier(authApi);
});

final dioAugmontProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
    validateStatus: (_) => true,
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = LocalStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        LocalStorageService.clearAuthSession();
      }
      handler.next(error);
    },
  ));
  return dio;
});
