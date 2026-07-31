import 'dart:math';

class QuantityHelper {
  static double truncateQuantity(double value, {int digits = 4}) {
    if (!value.isFinite) return 0;
    final factor = digits > 0 ? pow(10, digits).toDouble() : 1.0;
    return (value * factor).truncateToDouble() / factor;
  }

  static String formatQuantity(double value, {int digits = 4}) {
    return truncateQuantity(value, digits: digits).toStringAsFixed(digits);
  }
}
