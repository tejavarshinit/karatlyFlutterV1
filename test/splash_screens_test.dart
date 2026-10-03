import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karatly/features/splash/splash_screen_1.dart';
import 'package:karatly/features/splash/splash_screen_2.dart';
import 'package:karatly/features/splash/splash_screen_3.dart';

void main() {
  Future<void> runSplash(WidgetTester tester, Widget screen) async {
    final errors = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details.exceptionAsString());
    };

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp(home: screen));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    FlutterError.onError = previousOnError;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    final failures = errors
        .where((e) => !e.contains('Unable to load asset'))
        .toList();
    expect(failures, isEmpty, reason: failures.join('\n'));
  }

  testWidgets('SplashScreen1 renders without errors', (tester) async {
    await runSplash(tester, SplashScreen1(onSkip: () {}, onNext: () {}));
  });

  testWidgets('SplashScreen2 renders without errors', (tester) async {
    await runSplash(tester, SplashScreen2(onSkip: () {}, onNext: () {}));
  });

  testWidgets('SplashScreen3 renders without errors', (tester) async {
    await runSplash(tester, SplashScreen3(onLogin: () {}, onSignUp: () {}));
  });
}
