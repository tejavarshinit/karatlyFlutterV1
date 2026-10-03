import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'router.dart';
import '../core/services/auth_provider.dart';
import '../core/services/push_notification_service.dart';

class KaratlyApp extends ConsumerWidget {
  const KaratlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    PushNotificationService.instance.attachRouter(router);

    // Register the FCM device token with the backend whenever the user
    // becomes authenticated (fresh login or restored session).
    ref.listen<bool>(authProvider.select((s) => s.isAuthenticated), (prev, next) {
      if (next) PushNotificationService.instance.syncToken();
    });

    return MaterialApp.router(
      title: 'Karatly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
