import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/local_storage.dart';
import 'core/services/push_notification_service.dart';
import 'app/app.dart';
import 'features/platform/platform_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppForWeb();
  await LocalStorageService.init();
  await PushNotificationService.instance.init();
  runApp(const ProviderScope(child: KaratlyApp()));
}
