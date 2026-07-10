import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/storage/local_storage.dart';
import 'splash_screen_1.dart';
import 'splash_screen_2.dart';
import 'splash_screen_3.dart';

class SplashController extends StatefulWidget {
  const SplashController({super.key});

  @override
  State<SplashController> createState() => _SplashControllerState();
}

class _SplashControllerState extends State<SplashController> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_navigating || !mounted) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _completeSplash() {
    if (_navigating) return;
    _navigating = true;
    LocalStorageService.setHasSeenSplash(true);
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _navigateToSignup() {
    if (!mounted) return;
    LocalStorageService.setHasSeenSplash(true);
    context.go(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SplashScreen1(
            onSkip: _navigateToSignup,
            onNext: () => _goToPage(1),
          ),
          SplashScreen2(
            onSkip: _navigateToSignup,
            onNext: () => _goToPage(2),
          ),
          SplashScreen3(
            onSignUp: _navigateToSignup,
            onLogin: _navigateToLogin,
          ),
        ],
      ),
    );
  }
}
