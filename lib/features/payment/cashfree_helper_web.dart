import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

class CashfreeHelper {
  static String? getCheckoutHtml(String paymentSessionId) => null;

  static void loadSdkAndOpenCheckout({
    required String paymentSessionId,
    required void Function() onReady,
    required void Function(String error) onError,
  }) {
    const sdkUrl = 'https://sdk.cashfree.com/js/v3/cashfree.js';

    if (js.context.hasProperty('Cashfree')) {
      _openCheckout(paymentSessionId, onReady, onError);
      return;
    }

    final script = html.ScriptElement()
      ..src = sdkUrl
      ..async = true;

    script.onLoad.listen((_) {
      _openCheckout(paymentSessionId, onReady, onError);
    });
    script.onError.listen((_) {
      onError('Failed to load payment gateway SDK.');
    });

    html.document.head!.append(script);
  }

  static void _openCheckout(
    String paymentSessionId,
    void Function() onReady,
    void Function(String error) onError,
  ) {
    try {
      final cashfree = js.context.callMethod('Cashfree', [
        js.JsObject.jsify({'mode': 'sandbox'}),
      ]);

      onReady();

      cashfree.callMethod('checkout', [
        js.JsObject.jsify({
          'paymentSessionId': paymentSessionId,
        }),
      ]);
    } catch (e) {
      onError('Could not open payment gateway. Retrying...');
    }
  }
}
