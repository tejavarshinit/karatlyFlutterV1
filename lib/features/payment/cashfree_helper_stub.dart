import 'dart:convert';

import '../../core/api/config.dart';

class CashfreeHelper {
  static String? getCheckoutHtml(String paymentSessionId, {double amount = 0}) {
    final amountText = amount > 0 ? amount.toStringAsFixed(2) : '';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="${ApiConfig.cashfreeSdkUrl}"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: radial-gradient(103.89% 37.92% at 97.55% 0%, #293341 0%, #0A0F1A 100%);
      color: #ffffff;
      font-family: Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      width: 100%;
      max-width: 360px;
      border: 1px solid #2E2E2E;
      border-radius: 20px;
      background: rgba(26, 35, 50, 0.98);
      padding: 20px;
      box-shadow: 0 18px 60px rgba(0, 0, 0, 0.45);
    }
    .label { font-size: 11px; color: #7E7E7E; }
    .amount { font-size: 18px; font-weight: 700; margin-top: 4px; }
    .subtext { margin-top: 8px; font-size: 12px; line-height: 1.5; color: #B8C0CA; }
  </style>
</head>
<body>
  <div class="card">
    <div class="label">Amount payable</div>
    <div class="amount">${amountText.isNotEmpty ? '₹$amountText' : 'Opening checkout...'}</div>
    <div class="subtext">Secure checkout powered by Cashfree.</div>
  </div>
  <script>
    const cf = Cashfree({mode: '${ApiConfig.cashfreeMode}'});
    cf.checkout({
      paymentSessionId: '$paymentSessionId',
      redirectTarget: '_self',
    });
  </script>
</body>
</html>
''';
  }

  static String buildExternalBrowserCheckoutDataUrl(
    String paymentSessionId, {
    double amount = 0,
  }) {
    final amountText = amount > 0 ? amount.toStringAsFixed(2) : '';
    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cashfree Checkout</title>
  <script src="${ApiConfig.cashfreeSdkUrl}"></script>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      font-family: Arial, sans-serif;
      background: radial-gradient(103.89% 37.92% at 97.55% 0%, #293341 0%, #0A0F1A 100%);
      color: #fff;
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
      html,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();
  }

  static void loadSdkAndOpenCheckout({
    required String paymentSessionId,
    required void Function() onReady,
    required void Function(String error) onError,
  }) {}
}
