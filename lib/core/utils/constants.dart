import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Karatly';
  static const String appTagline = 'Buy Digital Gold & Silver';
  static const String appDescription = "India's trusted digital gold platform. Buy, sell, and store 24K 999 Pure Gold and Silver anytime.";
  static const String appId = 'com.karatly.app';

  // Gold settings
  static const int goldDigits = 4;
  static const int currencyDecimals = 2;
  static const String currencySymbol = '₹';
  static const String metalTypeGold = 'gold';
  static const String metalTypeSilver = 'silver';

  // Rate cache
  static const Duration rateCacheTtl = Duration(seconds: 60);
  static const int liveGoldRateHistoryLimit = 12;

  // Timeouts
  static const Duration otpTimeout = Duration(seconds: 60);
  static const Duration paymentTimeout = Duration(seconds: 30);
  static const Duration ocrTimeout = Duration(seconds: 60);

  // Auto advance delays
  static const int bankVerifyLoadDelay = 3000;
  static const int buy4Delay = 4000;
  static const int sell4Delay = 4000;
  static const int sip4Delay = 4000;
  static const int popupDelay = 5000;

  // Payment statuses
  static const String statusSuccess = 'SUCCESS';
  static const String statusFailed = 'FAILED';
  static const String statusPending = 'PENDING';
  static const String statusProcessing = 'PROCESSING';

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      locale: 'en_IN',
      decimalDigits: currencyDecimals,
    );
    return formatter.format(amount);
  }

  static String formatGrams(double grams) {
    return '${grams.toStringAsFixed(goldDigits)} g';
  }

  static String formatDate(String dateStr, {String pattern = 'dd MMM yyyy'}) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(pattern).format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
