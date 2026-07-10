class CashfreeHelper {
  static String? getCheckoutHtml(String paymentSessionId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #1A1918; font-family: sans-serif; }
    #cf-checkout { width: 100%; min-height: 100vh; }
  </style>
</head>
<body>
  <div id="cf-checkout"></div>
  <script>
    const cf = Cashfree({mode: 'sandbox'});
    cf.checkout({
      paymentSessionId: '$paymentSessionId',
      renderTarget: 'cf-checkout',
    });
  </script>
</body>
</html>
''';
  }

  static void loadSdkAndOpenCheckout({
    required String paymentSessionId,
    required void Function() onReady,
    required void Function(String error) onError,
  }) {}
}
