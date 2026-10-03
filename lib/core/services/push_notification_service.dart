import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../api/notification_api.dart';
import '../storage/local_storage.dart';
import '../utils/unique_id.dart';

/// All push logs are prefixed with [PUSH]. Filter with:
///   flutter run                   -> search "[PUSH]"
///   adb logcat | findstr PUSH     (Windows)
void pushLog(String message) => debugPrint('[PUSH] $message');

/// Background/terminated FCM handler. Messages carrying a `notification`
/// payload are displayed by the OS automatically; nothing else to do here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  pushLog('BACKGROUND message received | id=${message.messageId} '
      'title=${message.notification?.title} body=${message.notification?.body} data=${message.data}');
}

/// Firebase Cloud Messaging integration:
///  - obtains the FCM device token and registers it with the backend
///    (POST /api/v1/notification/device-token) together with the user's uniqueId,
///  - re-registers on token refresh / login,
///  - shows foreground notifications (Gold & Silver broadcast, GOLD_PURCHASE, ...),
///  - routes notification taps into the app.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _channel = AndroidNotificationChannel(
    'karatly_default',
    'Karatly Notifications',
    description: 'Gold & silver price alerts and order updates',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _api = NotificationApi();

  bool _enabled = false;
  String? _lastRegisteredKey;
  Future<void>? _syncInFlight;
  GoRouter? _router;
  Map<String, dynamic>? _pendingTapData;

  bool get isEnabled => _enabled;

  /// Call once from main() before runApp. Safe if Firebase config
  /// (google-services.json / GoogleService-Info.plist) is missing: push is
  /// simply disabled and the app keeps working.
  Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      pushLog('init skipped: unsupported platform');
      return;
    }
    try {
      final app = await Firebase.initializeApp();
      pushLog('Firebase initialized | projectId=${app.options.projectId} '
          'senderId=${app.options.messagingSenderId} appId=${app.options.appId}');
    } catch (e) {
      pushLog('Firebase init FAILED, push disabled: $e');
      return;
    }
    _enabled = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        pushLog('TAP on foreground notification | payload=$payload');
        if (payload == null || payload.isEmpty) return;
        try {
          _handleTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {}
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    pushLog('local notifications ready | channel=${_channel.id}');

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    // iOS: let the OS show banners while the app is in the foreground.
    await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      pushLog('TAP opened app from BACKGROUND | id=${m.messageId} data=${m.data}');
      _handleTap(m.data);
    });
    messaging.onTokenRefresh.listen((token) {
      pushLog('TOKEN refreshed | token=$token');
      _lastRegisteredKey = null;
      unawaited(syncToken(tokenOverride: token));
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      pushLog('TAP launched app from TERMINATED | id=${initial.messageId} data=${initial.data}');
      _pendingTapData = initial.data;
    }

    // Log the current token at startup (even before login) for manual FCM tests.
    unawaited(messaging.getToken().then(
          (t) => pushLog('TOKEN at startup | token=$t'),
          onError: (Object e) => pushLog('TOKEN fetch at startup FAILED: $e'),
        ));
    pushLog('init complete');
  }

  /// Wire the app router so notification taps can navigate.
  void attachRouter(GoRouter router) {
    if (identical(_router, router)) return;
    _router = router;
    final pending = _pendingTapData;
    if (pending != null) {
      _pendingTapData = null;
      // Let the router finish its first frame / auth redirects first.
      Future.delayed(const Duration(milliseconds: 800), () => _handleTap(pending));
    }
  }

  /// Requests permission (Android 13+ / iOS), fetches the FCM token and
  /// registers it with the backend. No-op when logged out, when the
  /// uniqueId is not known yet, or when this token+user was already sent
  /// in this session. Safe to call repeatedly.
  Future<void> syncToken({String? tokenOverride}) {
    if (!_enabled) {
      pushLog('sync skipped: push disabled (Firebase not initialized)');
      return Future.value();
    }
    return _syncInFlight ??= _doSync(tokenOverride).whenComplete(() => _syncInFlight = null);
  }

  Future<void> _doSync(String? tokenOverride) async {
    try {
      if (!LocalStorageService.isAuthenticated()) {
        pushLog('sync skipped: user not logged in');
        return;
      }
      final uniqueId = resolveUniqueId();
      if (uniqueId.isEmpty) {
        pushLog('sync skipped: uniqueId not available yet');
        return;
      }
      pushLog('sync started | uniqueId=$uniqueId');

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      pushLog('permission status=${settings.authorizationStatus.name}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        pushLog('WARNING: notification permission DENIED - notifications will not be shown');
        // Still register the token: the user may re-enable notifications
        // from system settings later.
      }

      if (Platform.isIOS) {
        // FCM token is only available once APNs has issued its token.
        String? apns = await messaging.getAPNSToken();
        for (var i = 0; apns == null && i < 5; i++) {
          await Future.delayed(const Duration(seconds: 1));
          apns = await messaging.getAPNSToken();
        }
        if (apns == null) {
          pushLog('APNs token unavailable (simulator or push capability missing)');
          return;
        }
        pushLog('APNs token ok');
      }

      final token = tokenOverride ?? await messaging.getToken();
      if (token == null || token.isEmpty) {
        pushLog('sync FAILED: FCM token is null/empty');
        return;
      }
      pushLog('FCM TOKEN | token=$token');

      final key = '$uniqueId|$token';
      if (key == _lastRegisteredKey) {
        pushLog('sync skipped: token already registered this session');
        return;
      }

      final res = await _api.registerDeviceToken(
        deviceToken: token,
        deviceType: Platform.isIOS ? 'IOS' : 'ANDROID',
        uniqueId: uniqueId,
      );
      if (res['ok'] == true) {
        _lastRegisteredKey = key;
        pushLog('REGISTER SUCCESS | id=${res['id']} created=${res['created']} '
            'isActive=${res['isActive']} message=${res['message']}');
      } else {
        pushLog('REGISTER FAILED | status=${res['statusCode']} message=${res['message']}');
      }
    } catch (e) {
      pushLog('sync FAILED with exception: $e');
    }
  }

  /// On logout, drop the FCM token so this device stops receiving the
  /// previous user's notifications. The backend marks the old token inactive
  /// the next time Firebase reports it as unregistered.
  Future<void> onLogout() async {
    _lastRegisteredKey = null;
    if (!_enabled) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
      pushLog('logout: FCM token deleted');
    } catch (e) {
      pushLog('logout: deleteToken FAILED: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    pushLog('FOREGROUND message received | id=${message.messageId} '
        'title=${message.notification?.title} body=${message.notification?.body} data=${message.data}');
    // iOS displays foreground banners itself (presentation options above).
    if (!Platform.isAndroid) return;
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString();
    final body = n?.body ?? message.data['body']?.toString();
    if (title == null && body == null) {
      pushLog('FOREGROUND message has no title/body - nothing shown');
      return;
    }

    _local
        .show(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: body != null ? BigTextStyleInformation(body) : null,
            ),
          ),
          payload: jsonEncode(message.data),
        )
        .then(
          (_) => pushLog('FOREGROUND notification displayed | title=$title'),
          onError: (Object e) => pushLog('FOREGROUND notification display FAILED: $e'),
        );
  }

  void _handleTap(Map<String, dynamic> data) {
    final router = _router;
    if (router == null) {
      pushLog('tap queued until router is ready');
      _pendingTapData = data;
      return;
    }
    if (!LocalStorageService.isAuthenticated()) {
      pushLog('tap ignored: user not logged in');
      return;
    }
    final type = data['type']?.toString().toUpperCase() ?? '';
    // Paths mirror AppRoutes.orders / AppRoutes.notifications.
    final target = type == 'GOLD_PURCHASE' ? '/orders' : '/notifications';
    pushLog('tap navigate | type=$type -> $target');
    router.push(target);
  }

  /// Same resolution order used across the app (augmont user → profile →
  /// stored id → mobile+DOB). Must match client_profile.provider_client_reference.
  static String resolveUniqueId() {
    final augmontUserRaw = LocalStorageService.getAugmontUser();
    if (augmontUserRaw != null && augmontUserRaw.isNotEmpty) {
      try {
        final augmontUser = jsonDecode(augmontUserRaw) as Map<String, dynamic>;
        final uniqueId = augmontUser['uniqueId']?.toString();
        if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
      } catch (_) {}
    }
    final storedProfile = LocalStorageService.getUserProfile();
    if (storedProfile != null) {
      final uniqueId = storedProfile['augmontUniqueId']?.toString() ?? storedProfile['uniqueId']?.toString();
      if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    }
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final dob = storedProfile?['dateOfBirth']?.toString() ?? '';
      return UniqueIdHelper.buildMobileDobUniqueId(mobileNumber: phone, dateOfBirth: dob);
    }
    return '';
  }
}
