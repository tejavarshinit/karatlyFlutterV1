import 'dart:math' as math;

class MoneyHelper {
  static double truncateMoney(double value, {int digits = 2}) {
    if (!value.isFinite) return 0;
    if (digits <= 0) return value.truncateToDouble();
    final factor = math.pow(10, digits).toDouble();
    return (value * factor).truncateToDouble() / factor;
  }

  static String formatMoney(double value, {int digits = 2}) {
    return truncateMoney(value, digits: digits).toStringAsFixed(digits);
  }
}
