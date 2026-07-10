import 'package:url_launcher/url_launcher.dart';

class PaymentRedirectHelper {
  static void handleFormRedirect({
    required String url,
    required String method,
    required Map<String, dynamic> payload,
  }) {
    final uri = Uri.parse(url).replace(queryParameters: payload.map((k, v) => MapEntry(k, v.toString())));
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void handlePostRedirect({required String url}) {
    final uri = Uri.parse(url);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
