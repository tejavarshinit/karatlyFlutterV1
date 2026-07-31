import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';

import '../../core/api/config.dart';

class CashfreeHelper {
  static String? getCheckoutHtml(String paymentSessionId, {double amount = 0}) => null;

  static String buildExternalBrowserCheckoutDataUrl(
    String paymentSessionId, {
    double amount = 0,
  }) {
    final amountText = amount > 0 ? amount.toStringAsFixed(2) : '';
    final htmlString = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cashfree Checkout</title>
  <script src="${ApiConfig.cashfreeSdkUrl}"></script>
  <style>
    :root { color-scheme: dark; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      font-family: Arial, sans-serif;
      background: radial-gradient(103.89% 37.92% at 97.55% 0%, #293341 0%, #0A0F1A 100%);
      color: #ffffff;
    }
    .card {
      width: min(420px, 100%);
      border: 1px solid #2E2E2E;
      border-radius: 20px;
      background: rgba(26, 35, 50, 0.98);
      padding: 20px;
      box-shadow: 0 18px 60px rgba(0, 0, 0, 0.45);
    }
    .title { font-size: 18px; font-weight: 700; }
    .sub { margin-top: 8px; font-size: 13px; color: #B8C0CA; line-height: 1.5; }
    .amount { margin-top: 14px; font-size: 22px; font-weight: 700; color: #F7CD57; }
    .hint { margin-top: 8px; font-size: 12px; color: #7E7E7E; }
  </style>
</head>
<body>
  <div class="card">
    <div class="title">Opening Cashfree checkout</div>
    <div class="sub">This will continue in your mobile browser so UPI apps can appear like the React flow.</div>
    <div class="amount">${amountText.isNotEmpty ? '₹$amountText' : 'Proceeding to payment...'}</div>
    <div class="hint">If the checkout does not open automatically, reload the page.</div>
  </div>
  <script>
    (async function () {
      try {
        const cashfree = Cashfree({ mode: '${ApiConfig.cashfreeMode}' });
        await cashfree.checkout({
          paymentSessionId: '$paymentSessionId',
          redirectTarget: '_self',
        });
      } catch (e) {
        document.querySelector('.sub').textContent = 'Unable to open checkout automatically.';
      }
    })();
  </script>
</body>
</html>
''';
    return Uri.dataFromString(
      htmlString,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();
  }

  static void loadSdkAndOpenCheckout({
    required String paymentSessionId,
    required void Function() onReady,
    required void Function(String error) onError,
  }) {
    const sdkUrl = ApiConfig.cashfreeSdkUrl;

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
        js.JsObject.jsify({'mode': ApiConfig.cashfreeMode}),
      ]);

      onReady();

      cashfree.callMethod('checkout', [
        js.JsObject.jsify({
          'paymentSessionId': paymentSessionId,
          'redirectTarget': '_self',
        }),
      ]);
    } catch (e) {
      onError('Could not open payment gateway. Retrying...');
    }
  }
}
