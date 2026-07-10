import 'dart:html' as html;

class PaymentRedirectHelper {
  static void handleFormRedirect({
    required String url,
    required String method,
    required Map<String, dynamic> payload,
  }) {
    final form = html.FormElement()
      ..method = method
      ..action = url;

    payload.forEach((key, value) {
      final input = html.InputElement()
        ..type = 'hidden'
        ..name = key
        ..value = value.toString();
      form.children.add(input);
    });

    html.document.body?.children.add(form);
    form.submit();
  }

  static void handlePostRedirect({required String url}) {
    if (url.isNotEmpty) {
      html.window.location.href = url;
    }
  }
}
