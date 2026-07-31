import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/lock_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/market/market_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/buy_flow/buy_screen.dart';
import '../features/sell_flow/sell_screen.dart';
import '../features/sip_flow/sip_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/brands/brands_screen.dart';
import '../features/payment/payment_gateway_screen.dart';

import '../features/payment/payment_return_screen.dart';
import '../features/settings/help_center_screen.dart';
import '../features/settings/terms_screen.dart';
import '../features/settings/privacy_policy_screen.dart';
import '../features/settings/security_screen.dart';
import '../features/settings/refund_policy_screen.dart';
import '../features/settings/terms_of_use_screen.dart';
import '../features/settings/trademark_notice_screen.dart';
import '../features/settings/how_it_works_screen.dart';
import '../features/settings/why_karatly_screen.dart';
import '../features/commerce/rewards_screen.dart';
import '../features/commerce/transfer_screen.dart';
import '../features/commerce/gold_certificate_screen.dart';
import '../features/commerce/audit_certificate_screen.dart';
import '../features/certificate/silver_certificate_screen.dart';
import '../features/certificate/diamond_certificate_screen.dart';
import '../features/invoice/invoice_screen.dart';
import '../features/commerce/bank_verify_screen.dart';
import '../features/commerce/bank_verify_loading_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/kyc/kyc_verification_screen.dart';
import '../features/gift360/gift360_webview_screen.dart';
import '../features/payment/payment_methods_screen.dart';
import '../features/buy_flow/buy_selection_screen.dart';
import '../features/sell_flow/sell_selection_screen.dart';
import '../features/sell_flow/gold_coin_screen.dart';
import '../features/diamond_flow/buy_diamonds_screen.dart';
import '../features/diamond_flow/diamond_payment_success_screen.dart';
import '../shared/widgets/bottom_nav_shell.dart';
import '../core/services/auth_provider.dart';
import '../features/splash/splash_controller.dart';

class AppRoutes {
  AppRoutes._();

  // Auth
  static const lock = '/lock';
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/otp';
  static const signup = '/signup';

  // Main tabs
  static const home = '/home';
  static const dashboard = '/dashboard';
  static const market = '/market';
  static const orders = '/orders';
  static const profile = '/profile';
  static const cart = '/cart';
  static const categories = '/categories';
  static const brands = '/brands';

  // Buy flow
  static const buySelect = '/buy';
  static const buy1 = '/buy/buy/1';
  static const buy2 = '/buy/buy/2';
  static const buy3 = '/buy/buy/3';
  static const buy4 = '/buy/buy/4';
  static const buy5 = '/buy/buy/5';

  // Sell flow
  static const sell1 = '/sell/sell/1';
  static const sell2 = '/sell/sell/2';
  static const sell3 = '/sell/sell/3';
  static const sell4 = '/sell/sell/4';
  static const sell5 = '/sell/sell/5';

  // SIP flow
  static const sip1 = '/sip/1';
  static const sip2 = '/sip/2';
  static const sip3 = '/sip/3';
  static const sip4 = '/sip/4';
  static const sip5 = '/sip/5';

  // Coin flow
  static const coin1 = '/coin/1';
  static const coinReview = '/coin/review';
  static const coinAddress = '/coin/address';
  static const coin2 = '/coin/2';
  static const coin3 = '/coin/3';

  // Gold Coin flow
  static const goldCoin1 = '/buy/gold-coin/1';
  static const goldCoinReview = '/buy/gold-coin/review';
  static const goldCoin2 = '/buy/gold-coin/2';
  static const goldCoin3 = '/buy/gold-coin/3';
  static const sellGoldCoin1 = '/sell/gold-coin/1';
  static const sellGoldCoinReview = '/sell/gold-coin/review';
  static const sellGoldCoin2 = '/sell/gold-coin/2';
  static const sellGoldCoinPay = '/sell/gold-coin/pay';
  static const sellGoldCoin3 = '/sell/gold-coin/3';

  // Sell Silver flow
  static const sellSilver1 = '/sell-silver/1';
  static const sellSilver2 = '/sell-silver/2';
  static const sellSilver3 = '/sell-silver/3';
  static const sellSilver4 = '/sell-silver/4';
  static const sellSilver5 = '/sell-silver/5';
  static const sellSilverUpi = '/sell-silver/upi';
  static const sellSilverBank = '/sell-silver/bank';
  static const sellSilverVerify = '/sell-silver/verify';
  static const sellSilverVerified = '/sell-silver/verified';

  // Silver SIP flow
  static const silverSip1 = '/silver-sip/1';
  static const silverSip2 = '/silver-sip/2';
  static const silverSip3 = '/silver-sip/3';
  static const silverSip4 = '/silver-sip/4';
  static const silverSip5 = '/silver-sip/5';
  static const silverSip6 = '/silver-sip/6';

  // Diamond flow
  static const buyDiamonds = '/buy-diamonds';

  // Selection
  static const buyGoldSelect = '/buy-gold/select';
  static const sellGoldSelect = '/sell-gold/select';

  // Other
  static const portfolio = '/portfolio';
  static const goldCertificate = '/gold-certificate';
  static const auditCertificate = '/audit-certificate';
  static const silverCertificate = '/silver-certificate';
  static const diamondCertificate = '/diamond-certificate';
  static const diamondPaymentSuccess = '/diamond-payment-success';
  static const kycVerification = '/kyc-verification';
  static const paymentMethods = '/payment-methods';
  static const paymentGateway = '/payment-gateway';
  static const paymentReturn = '/payment/return';

  static const rewards = '/rewards';
  static const security = '/security';
  static const helpCenter = '/help-center';
  static const terms = '/terms';
  static const privacyPolicy = '/privacy-policy';
  static const refundPolicy = '/refund-policy';
  static const termsOfUse = '/terms-of-use';
  static const trademarkNotice = '/trademark-notice';
  static const howItWorks = '/how-it-works';
  static const transfer = '/transfer';
  static const why = '/why';
  static const notifications = '/notifications';
  static const invoice = '/invoice';
  static const partner = '/partner';
  static const nearby = '/nearby';
  static const bankVerify = '/bank-verify';
  static const bankVerifyLoading = '/bank-verify-loading';
  static const gift360 = '/gift360';
}


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(
    authProvider.select((state) => (
      isAuthenticated: state.isAuthenticated,
      loading: state.loading,
    )),
  );

  return GoRouter(
    initialLocation: AppRoutes.lock,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.loading;
      final path = state.uri.path;

      bool isPublicAuthRoute(String location) {
        return location == AppRoutes.login ||
            location == AppRoutes.signup ||
            location == AppRoutes.otp ||
            location == AppRoutes.splash ||
            location == AppRoutes.lock;
      }

      if (isLoading) return null;

      if (!isLoggedIn && !isPublicAuthRoute(path)) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isPublicAuthRoute(path)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.lock, builder: (_, __) => const LockScreen()),
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashController()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.otp, builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return OtpScreen(
          mobileNumber: extras['mobileNumber'] as String? ?? '',
          type: extras['type'] as String? ?? 'login',
          email: extras['email'] as String? ?? '',
          fullName: extras['fullName'] as String? ?? '',
          dateOfBirth: extras['dateOfBirth'] as String? ?? '',
        );
      }),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),

      ShellRoute(
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: AppRoutes.market, builder: (_, __) => const MarketScreen()),
          GoRoute(path: AppRoutes.orders, builder: (_, __) => const OrdersScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
          GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
          GoRoute(path: AppRoutes.categories, builder: (_, __) => const MarketScreen()),
          GoRoute(path: AppRoutes.brands, builder: (_, __) => const BrandsScreen()),
        ],
      ),

      GoRoute(path: AppRoutes.buyGoldSelect, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuySelectionScreen(metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buyDiamonds, builder: (_, __) => const BuyDiamondsScreen()),
      GoRoute(path: AppRoutes.diamondPaymentSuccess, builder: (_, __) => const DiamondPaymentSuccessScreen()),
      GoRoute(path: AppRoutes.sellGoldSelect, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellSelectionScreen(metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buySelect, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuyScreen(metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buy1, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuyScreen(step: 1, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buy2, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuyScreen(step: 2, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buy3, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuyScreen(step: 3, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buy4, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuyScreen(step: 4, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.buy5, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return BuyScreen(step: 5, metalType: metalType);
      }),

      GoRoute(path: AppRoutes.sellGoldSelect, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellScreen(step: 1, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.sell1, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellScreen(step: 1, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.sell2, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellScreen(step: 2, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.sell3, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellScreen(step: 3, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.sell4, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellScreen(step: 4, metalType: metalType);
      }),
      GoRoute(path: AppRoutes.sell5, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        return SellScreen(step: 5, metalType: metalType);
      }),

      // Gold coin sell/redeem flow
      GoRoute(path: AppRoutes.sellGoldCoin1, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        final backRoute = state.uri.queryParameters['back'] ?? AppRoutes.market;
        return GoldCoinScreen(step: 1, metalType: metalType, backRoute: backRoute);
      }),
      GoRoute(path: AppRoutes.sellGoldCoinReview, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        final backRoute = state.uri.queryParameters['back'] ?? AppRoutes.market;
        return GoldCoinScreen(step: 2, metalType: metalType, backRoute: backRoute);
      }),
      GoRoute(path: AppRoutes.sellGoldCoin2, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        final backRoute = state.uri.queryParameters['back'] ?? AppRoutes.market;
        return GoldCoinScreen(step: 3, metalType: metalType, backRoute: backRoute);
      }),
      GoRoute(path: AppRoutes.sellGoldCoin3, builder: (_, state) {
        final metalType = state.uri.queryParameters['metal'] ?? 'gold';
        final backRoute = state.uri.queryParameters['back'] ?? AppRoutes.market;
        return GoldCoinScreen(step: 4, metalType: metalType, backRoute: backRoute);
      }),

      GoRoute(path: AppRoutes.sip1, builder: (_, __) => const SipScreen(step: 1)),
      GoRoute(path: AppRoutes.sip2, builder: (_, __) => const SipScreen(step: 2)),
      GoRoute(path: AppRoutes.sip3, builder: (_, __) => const SipScreen(step: 3)),
      GoRoute(path: AppRoutes.sip4, builder: (_, __) => const SipScreen(step: 4)),
      GoRoute(path: AppRoutes.sip5, builder: (_, __) => const SipScreen(step: 5)),

      GoRoute(path: AppRoutes.paymentGateway, builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return PaymentGatewayScreen(
          paymentSessionId: extras['paymentSessionId'] as String? ?? '',
          orderId: extras['orderId'] as String? ?? '',
          paymentAmount: (extras['amount'] as num?)?.toDouble() ?? 0,
          paymentRequest: extras['paymentRequest'] as Map<String, dynamic>?,
        );
      }),
      GoRoute(path: AppRoutes.paymentReturn, builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        final orderId = extras['orderId'] as String? ?? state.uri.queryParameters['order_id'] ?? '';
        return PaymentReturnScreen(orderId: orderId);
      }),

      GoRoute(path: AppRoutes.rewards, builder: (_, __) => const RewardsScreen()),
      GoRoute(path: AppRoutes.transfer, builder: (_, __) => const TransferScreen()),
      GoRoute(path: AppRoutes.goldCertificate, builder: (_, __) => const GoldCertificateScreen()),
      GoRoute(path: AppRoutes.auditCertificate, builder: (_, __) => const AuditCertificateScreen()),
      GoRoute(path: AppRoutes.silverCertificate, builder: (_, __) => const SilverCertificateScreen()),
      GoRoute(path: AppRoutes.diamondCertificate, builder: (_, __) => const DiamondCertificateScreen()),
      GoRoute(path: AppRoutes.invoice, builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return InvoiceScreen(
          transactionId: extras['transactionId'] as String? ?? '',
          type: extras['type'] as String? ?? 'buy',
        );
      }),
      GoRoute(path: AppRoutes.bankVerify, builder: (_, __) => const BankVerifyScreen()),
      GoRoute(path: AppRoutes.bankVerifyLoading, builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return BankVerifyLoadingScreen(details: extras);
      }),
      GoRoute(path: AppRoutes.kycVerification, builder: (_, __) => const KycVerificationScreen()),
      GoRoute(path: AppRoutes.paymentMethods, builder: (_, __) => const PaymentMethodsScreen()),

      GoRoute(path: AppRoutes.helpCenter, builder: (_, __) => const HelpCenterScreen()),
      GoRoute(path: AppRoutes.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(path: AppRoutes.privacyPolicy, builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: AppRoutes.security, builder: (_, __) => const SecurityScreen()),
      GoRoute(path: AppRoutes.refundPolicy, builder: (_, __) => const RefundPolicyScreen()),
      GoRoute(path: AppRoutes.termsOfUse, builder: (_, __) => const TermsOfUseScreen()),
      GoRoute(path: AppRoutes.trademarkNotice, builder: (_, __) => const TrademarkNoticeScreen()),
      GoRoute(path: AppRoutes.howItWorks, builder: (_, __) => const HowItWorksScreen()),
      GoRoute(path: AppRoutes.why, builder: (_, __) => const WhyKaratlyScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.gift360, builder: (_, __) => const Gift360WebViewScreen()),

      GoRoute(path: '/', redirect: (_, __) => AppRoutes.splash),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});
