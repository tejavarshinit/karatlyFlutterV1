class UniqueIdHelper {
  static String _formatDobForUniqueId(String dateOfBirth) {
    final value = dateOfBirth.trim();
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (isoMatch != null) {
      final year = isoMatch.group(1);
      final month = isoMatch.group(2);
      final day = isoMatch.group(3);
      return '$day$month$year';
    }
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String buildMobileDobUniqueId({
    String mobileNumber = '',
    String dateOfBirth = '',
  }) {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '').substring(
      mobileNumber.replaceAll(RegExp(r'\D'), '').length >= 10
          ? mobileNumber.replaceAll(RegExp(r'\D'), '').length - 10
          : 0,
    );
    final cleanDob = _formatDobForUniqueId(dateOfBirth);
    if (cleanMobile.isNotEmpty && cleanDob.isNotEmpty) {
      return '$cleanMobile$cleanDob';
    }
    if (cleanMobile.isNotEmpty) {
      return 'KTL-$cleanMobile';
    }
    return '';
  }

  static String buildAugmontUniqueId(String mobileNumber) {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '').substring(
      mobileNumber.replaceAll(RegExp(r'\D'), '').length >= 10
          ? mobileNumber.replaceAll(RegExp(r'\D'), '').length - 10
          : 0,
    );
    return cleanMobile.isNotEmpty ? 'KTL-$cleanMobile' : '';
  }
}
