import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'invoice_data_service.dart';

// ── Entity constants (matching React) ──
const _augmontName = 'AUGMONT GOLDTECH PRIVATE LIMITED';
const _augmontCin = 'CIN: U51909MH2020PTC337639';
const _augmontGstin = '27AATCA3030A1Z3';
const _augmontPan = 'AATCA3030A';
const _augmontAddress = 'Unit No. 1A, 1st Floor, A-Trade Garden, Kamala Mills Compound, Senapati Bapat Marg, Delisle Road, above Bombay Canteen, Lower Parel, Mumbai, Maharashtra - 400013';
const _augmontContact = 'Tel: +91 9090906867  |  Email: support@augmont.com  |  Web: www.augmont.com';
const _augmontAuth = 'Auth. by: Mr. Sachin Kothari, Director';

const _karatlyName = 'KARATLY';
const _karatlyFullName = 'Karatly Finvest Technology India Private Limited';
const _karatlyAddress = 'HSR Layout, Sec 6, Bangalore \u2013 560102';
const _karatlyGstin = '29AAMCK8013A1ZN';
const _karatlyPan = 'AAMCK8013A';
const _karatlyEmail = 'support@karatly.net';
const _karatlyWeb = 'www.karatly.net';

// ── Terms (matching React) ──
const _buyTerms = [
  '1. Goods once sold will not be returned.',
  '2. Any disputes shall be subject to Mumbai jurisdiction.',
  '3. Our responsibility ceases once the goods are delivered to the customer.',
  '4. I/We hereby certify that my/our registration certificate under the Central Goods and Services Act, 2017 is in force on the date on which the sale of goods specified in this tax invoice is made by me/us and that the transaction of sale covered by this tax invoice has been effected by me/us and it shall be accounted for in the turnover of sales while filing of return and the due tax, if any, payable on the sale has been paid or shall be paid.',
  '5. This is a system generated document hence signature is not required.',
];

const _sellTerms = [
  '1. Once a sell-back order is placed and Sale-Back Confirmation is issued by Augmont, it cannot be reversed or cancelled.',
  '2. Any disputes shall be subject to Bengaluru jurisdiction.',
  '3. Karatly acts as a digital intermediary and facilitates gold/silver transactions on behalf of its users.',
  '4. Sale-back proceeds are credited ONLY to the Customer\'s registered bank account \u2014 no third-party transfers permitted.',
  '5. Gains on gold/silver sale-back may be subject to capital gains tax under the Income Tax Act, 1961. Consult your CA / tax advisor.',
  '6. This is a system generated document and does not require a physical signature.',
];

const _redeemTerms = [
  '1. Making and delivery charges are non-refundable once the redemption order is confirmed.',
  '2. BIS hallmarking compliance is the responsibility of Augmont Goldtech Private Limited.',
  '3. Karatly Finvest Technology India Private Limited acts as a digital intermediary only.',
  '4. This is a system generated document and does not require a physical signature.',
];

const _buyDeclaration = 'The above quantity of precious metal is held by Augmont Goldtech Private Limited in a secured, insured, third-party vault jointly monitored with an Independent Trustee, on behalf of the Customer. Title passed to the Customer at the moment of Sale Confirmation. It may be gifted, sold back to Augmont-Bullion (48-hour restriction applies), or redeemed as a physical minted product. Making and delivery charges apply at redemption. Karatly Finvest Technology India Private Limited acts as a digital intermediary only \u2014 NOT the seller of Gold or Silver.';

const _sellDeclaration = 'Karatly Finvest Technology India Private Limited facilitated this sale-back transaction as a digital intermediary only and is not liable for the sell-back rate, rate determination, or payout beyond the platform service charge collected on this transaction. Title has passed to Augmont-Bullion at Sale-Back Confirmation.';

const _redeemDeclaration = 'Augmont Goldtech Private Limited declares that the above products have been manufactured / sourced to the declared purity and weight, packaged in individually serial-numbered, assay-certified, tamper-proof packaging, and dispatched to the Customer\'s delivery address. All BIS hallmarking requirements have been complied with. Karatly Finvest Technology India Private Limited facilitated this redemption as a digital intermediary and is NOT the seller or manufacturer of the physical product.';

const _regulatoryNotice = 'Digital Gold / Silver are NOT regulated by SEBI or RBI. Investor protection under SEBI / RBI does not apply. This is not an investment product. Gains may be subject to capital gains tax \u2014 consult your CA. SEBI Advisory, 8 November 2025.';

// ── Colours (matching React) ──
const _cGold = 0xFFB8860B;
const _cNavy = 0xFF003366;
const _cBlack = 0xFF1E1E1E;
const _cWhite = 0xFFFFFFFF;
const _cGreyL = 0xFFF5F5F5;
const _cGreyM = 0xFFC8C8C8;
const _cRedBg = 0xFFFFF8F0;
const _cRedT = 0xFFA0280A;
const _cGrnBg = 0xFFF0FAF4;
const _cGrnT = 0xFF146428;
const _cBluBg = 0xFFF0F6FF;
const _cBluT = 0xFF143C8C;

late pw.Font _regFont;
late pw.Font _boldFont;
pw.MemoryImage? _logoImage;

pw.TextStyle _s(double size, {bool bold = false, int color = _cBlack, double? ls}) {
  return pw.TextStyle(
    font: bold ? _boldFont : _regFont,
    fontSize: size,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: PdfColor.fromInt(color),
    letterSpacing: ls,
  );
}

// ── Amount in words helper (matching React toWords) ──
String _toWords(num n) {
  final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
  final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
  String h(int n) {
    if (n == 0) return '';
    if (n < 20) return '${ones[n]} ';
    if (n < 100) return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${ones[n % 10]}' : ''} ';
    return '${ones[n ~/ 100]} Hundred ${h(n % 100)}';
  }
  final r = n.floor();
  final p = ((n - r) * 100).round();
  if (r == 0 && p == 0) return 'Zero Only';
  String s = '';
  if (r >= 10000000) s += '${h(r ~/ 10000000)}Crore ';
  if (r % 10000000 >= 100000) s += '${h((r % 10000000) ~/ 100000)}Lakh ';
  if (r % 100000 >= 1000) s += '${h((r % 100000) ~/ 1000)}Thousand ';
  s += h(r % 1000);
  s = s.trim();
  if (p > 0) s += ' and ${h(p).trim()} Paise';
  return '$s Only';
}

String _safeStr(dynamic v, [String fallback = '\u2014']) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isNotEmpty ? s : fallback;
}

String _safeNumStr(dynamic v, {int decimals = 2}) {
  if (v == null) return '0.00';
  final n = double.tryParse(v.toString());
  if (n == null || !n.isFinite) return '0.00';
  return n.toStringAsFixed(decimals);
}

String _fmtAmt(dynamic v) {
  final n = double.tryParse(v?.toString() ?? '') ?? 0;
  final fmt = n.toStringAsFixed(2);
  final parts = fmt.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return 'Rs. ${buf.toString()}.${parts[1]}';
}

// ── Main PDF generator ──
Future<Uint8List> generateInvoicePdf(InvoiceData data, String type) async {
  final reg = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final bld = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  _regFont = pw.Font.ttf(reg);
  _boldFont = pw.Font.ttf(bld);

  final logoBytes = await rootBundle.load('assets/images/KaratlyLOGO-removebg-preview.png');
  _logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final doc = pw.Document();

  if (type == 'buy') {
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 18),
      build: (ctx) => _buildBuyInvoice(data),
    ));
  } else if (type == 'sell') {
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 18),
      build: (ctx) => _buildSellInvoice(data),
    ));
  } else if (type == 'redeem') {
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 18),
      build: (ctx) => _buildRedeemInvoice(data),
    ));
  }

  return doc.save();
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED BUILDING BLOCKS
// ═══════════════════════════════════════════════════════════════════════════

pw.Widget _goldBar() {
  return pw.Column(children: [
    pw.Container(height: 2.5, color: PdfColor.fromInt(_cGold)),
    pw.SizedBox(height: 0),
  ]);
}

pw.Widget _karatlyHeader() {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(_karatlyName, style: _s(14, bold: true, color: _cGold)),
        pw.SizedBox(height: 1),
        pw.Text(_karatlyFullName, style: _s(7.5)),
        pw.SizedBox(height: 1),
        pw.Text(_karatlyAddress, style: _s(7.5)),
        pw.SizedBox(height: 1),
        pw.Text('GSTIN: $_karatlyGstin  |  PAN: $_karatlyPan', style: _s(7.5)),
        pw.SizedBox(height: 1),
        pw.Text('$_karatlyEmail  |  $_karatlyWeb', style: _s(7.5)),
      ])),
      if (_logoImage != null)
        pw.Container(
          width: 70.9,
          height: 70.9,
          child: pw.Image(_logoImage!),
        ),
    ]),
    pw.SizedBox(height: 5),
    pw.Container(height: 0.7, color: PdfColor.fromInt(_cGold)),
    pw.SizedBox(height: 4),
  ]);
}

pw.Widget _docTitle(String title, String subtitle) {
  return pw.Column(children: [
    pw.Text(title, style: _s(13, bold: true), textAlign: pw.TextAlign.center),
    pw.SizedBox(height: 2),
    pw.Text(subtitle, style: _s(8, color: 0xFF505050), textAlign: pw.TextAlign.center),
    pw.SizedBox(height: 6),
  ]);
}

pw.Widget _metaBox(List<Map<String, String>> rows) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(_cGreyL),
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
    ),
    child: pw.Column(children: rows.map((r) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
      child: pw.Row(children: [
        pw.Text(r['label']!, style: _s(7.5, bold: true)),
        pw.SizedBox(width: 4),
        pw.Expanded(child: pw.Text(r['value']!, style: _s(7.5))),
      ]),
    )).toList()),
  );
}

pw.Widget _sectionBar(String label) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    color: PdfColor.fromInt(_cNavy),
    child: pw.Text(label, style: _s(7.5, bold: true, color: _cWhite)),
  );
}

pw.Widget _kvRow(String label, String value, {bool shade = false}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: shade ? PdfColor.fromInt(_cGreyL) : PdfColor.fromInt(_cWhite),
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
    child: pw.Row(children: [
      pw.SizedBox(width: 62, child: pw.Text(label, style: _s(7, bold: true))),
      pw.Expanded(child: pw.Text(value, style: _s(7))),
    ]),
  );
}

pw.Widget _chargeRow(String label, String amount, {bool shade = false, bool isTotal = false}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: isTotal ? PdfColor.fromInt(_cNavy) : (shade ? PdfColor.fromInt(_cGreyL) : PdfColor.fromInt(_cWhite)),
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
    child: pw.Row(children: [
      pw.Expanded(child: pw.Text(label, style: _s(7.5, bold: isTotal, color: isTotal ? _cWhite : _cBlack))),
      pw.Text(amount, style: _s(7.5, bold: isTotal, color: isTotal ? _cWhite : _cBlack)),
    ]),
  );
}

pw.Widget _partyBox(String leftTitle, List<String> leftLines, String rightTitle, List<String> rightLines) {
  final maxLines = leftLines.length > rightLines.length ? leftLines.length : rightLines.length;
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(child: _partyHalf(leftTitle, leftLines, maxLines)),
    pw.SizedBox(width: 4),
    pw.Expanded(child: _partyHalf(rightTitle, rightLines, maxLines)),
  ]);
}

pw.Widget _partyHalf(String title, List<String> lines, int maxLines) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
      color: PdfColor.fromInt(_cNavy),
      child: pw.Text(title, style: _s(6.8, bold: true, color: _cWhite)),
    ),
    pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        for (var i = 0; i < lines.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Text(lines[i], style: _s(6.8, bold: i == 0)),
          ),
        if (lines.length < maxLines)
          for (var i = 0; i < maxLines - lines.length; i++) pw.SizedBox(height: 4),
      ]),
    ),
  ]);
}

pw.Widget _paymentInfo(String method, String ref, String date) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _sectionBar('Payment information'),
    pw.SizedBox(height: 2),
    pw.Row(children: [
      pw.Expanded(child: _payCol('Payment method', method)),
      pw.Expanded(child: _payCol('Payment reference (UTR / RRN / TXN ID)', ref)),
      pw.Expanded(child: _payCol('Payment date & time', date)),
    ]),
    pw.SizedBox(height: 4),
  ]);
}

pw.Widget _payCol(String label, String value) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(_cGreyL),
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
    ),
    padding: const pw.EdgeInsets.all(1),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: _s(6.5, bold: true, color: 0xFF505050)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: _s(7.5)),
    ]),
  );
}

pw.Widget _balanceRow(String title, String before, String delta, String after, {bool isNegative = false}) {
  final deltaColor = isNegative ? _cRedT : _cGrnT;
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _sectionBar(title),
    pw.SizedBox(height: 2),
    pw.Row(children: [
      pw.Expanded(child: _balCol('Balance before', before)),
      pw.Expanded(child: _balCol('This transaction', delta, valueColor: deltaColor)),
      pw.Expanded(child: _balCol('Balance after', after)),
    ]),
    pw.SizedBox(height: 4),
  ]);
}

pw.Widget _balCol(String label, String value, {int? valueColor}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(_cGreyL),
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
    ),
    padding: const pw.EdgeInsets.all(1),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: _s(6.5, bold: true, color: 0xFF505050)),
      pw.SizedBox(height: 3),
      pw.Text(value, style: _s(8, bold: true, color: valueColor ?? _cBlack)),
    ]),
  );
}

pw.Widget _noticeBox(String heading, String body, int fillColor, int textColor) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(3),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(fillColor),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(heading, style: _s(7.5, bold: true, color: textColor)),
      pw.SizedBox(height: 2),
      pw.Text(body, style: _s(6.8, color: textColor)),
    ]),
  );
}

pw.Widget _termsBlock(String declaration, List<String> terms, String regulatory) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.2),
    ),
    padding: const pw.EdgeInsets.all(2),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Declaration', style: _s(7.5, bold: true)),
      pw.SizedBox(height: 2),
      pw.Text(declaration, style: _s(6.8)),
      pw.SizedBox(height: 4),
      pw.Text('Terms & Conditions', style: _s(7.5, bold: true)),
      pw.SizedBox(height: 2),
      for (final term in terms) pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.Text(term, style: _s(6.8)),
      ),
      pw.SizedBox(height: 2),
      pw.Text('This is a computer-generated document and does not require a physical signature.  E. & O.E.', style: _s(6.5, color: 0xFF5A5A5A)),
      pw.SizedBox(height: 4),
      _noticeBox('REGULATORY NOTICE', regulatory, 0xFFEEEEEE, 0xFF3C3C3C),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// BUY INVOICE
// ═══════════════════════════════════════════════════════════════════════════

List<pw.Widget> _buildBuyInvoice(InvoiceData data) {
  final inv = data.raw;
  final metalType = (inv['metalType'] as String? ?? data.metalType).toUpperCase();
  final metalLabel = metalType == 'SILVER' ? 'Silver' : 'Gold';
  final txnType = metalType == 'SILVER' ? 'SILVER BUY' : 'GOLD BUY / SIP';

  final invoiceNo = _safeStr(inv['invoiceNumber'] ?? 'KAR-BUY-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}');
  final invoiceDate = _safeStr(inv['invoiceDate'] ?? DateTime.now().toIso8601String());
  final orderNo = _safeStr(inv['transactionId'] ?? inv['merchantTransactionId'] ?? data.transactionId);
  final saleConf = orderNo;
  final hsnCode = metalType == 'SILVER' ? '7106' : '7108';
  final productLabel = metalType == 'SILVER' ? '999 Fine Silver' : '24 Karat 999 Fine Gold';
  final rate = double.tryParse(inv['rate']?.toString() ?? '') ?? data.rate;
  final qty = double.tryParse(inv['quantity']?.toString() ?? inv['gold']?.toString() ?? '') ?? data.quantity;
  final gross = double.tryParse(inv['grossAmount']?.toString() ?? inv['totalAmount']?.toString() ?? '') ?? data.amount;
  final net = double.tryParse(inv['netAmount']?.toString() ?? inv['totalAmount']?.toString() ?? '') ?? data.totalAmount;

  final taxes = inv['taxes'] as Map<String, dynamic>? ?? {};
  final taxSplit = (taxes['taxSplit'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
  final cgst = taxSplit.cast<Map<String, dynamic>?>().firstWhere((t) => t?['type'] == 'CGST', orElse: () => null);
  final sgst = taxSplit.cast<Map<String, dynamic>?>().firstWhere((t) => t?['type'] == 'SGST', orElse: () => null);
  final igst = taxSplit.cast<Map<String, dynamic>?>().firstWhere((t) => t?['type'] == 'IGST', orElse: () => null);
  final cgstAmt = double.tryParse(cgst?['taxAmount']?.toString() ?? '') ?? 0;
  final sgstAmt = double.tryParse(sgst?['taxAmount']?.toString() ?? '') ?? 0;
  final igstAmt = double.tryParse(igst?['taxAmount']?.toString() ?? '') ?? 0;

  final discount = inv['discount'];
  double discountAmt = 0;
  if (discount is Map) {
    discountAmt = double.tryParse((discount['amount'] ?? discount['value'] ?? 0).toString()) ?? 0;
  } else {
    discountAmt = double.tryParse(discount?.toString() ?? '') ?? 0;
  }
  final tcsAmt = double.tryParse(inv['tcs']?.toString() ?? '') ?? 0;

  final paymentMethod = _safeStr(inv['paymentMethod'] ?? inv['paymentMode'] ?? inv['show_payment_mode'] ?? data.paymentMethod, 'UPI');
  final paymentRef = _safeStr(inv['paymentRef'] ?? inv['transactionId'] ?? data.transactionId);
  final paymentDate = _safeStr(inv['paymentDate'] ?? inv['invoiceDate'] ?? data.date);

  final balanceBefore = double.tryParse(inv['balanceBefore']?.toString() ?? data.balanceBefore.toString()) ?? data.balanceBefore;
  final balanceAfter = double.tryParse(inv['balanceAfter']?.toString() ?? data.balanceAfter.toString()) ?? data.balanceAfter;

  String fmt(num v) => v.toStringAsFixed(4);

  return [
    _goldBar(),
    pw.SizedBox(height: 6),
    _karatlyHeader(),
    _docTitle('TAX INVOICE', 'Gold / Silver Purchase'),
    _metaBox([
      {'label': 'Invoice no.         :', 'value': invoiceNo},
      {'label': 'Invoice date & time :', 'value': invoiceDate},
      {'label': 'Order no.           :', 'value': orderNo},
      {'label': 'Sale Conf. Ref.     :', 'value': saleConf},
      {'label': 'Transaction type    :', 'value': txnType},
    ]),
    pw.SizedBox(height: 8),
    _partyBox(
      'SOLD BY \u2014 Seller of Gold / Silver',
      [_augmontName, _augmontAddress.substring(0, 70), _augmontAddress.substring(70), 'GSTIN: $_augmontGstin  |  PAN: $_augmontPan', _augmontAuth],
      'BILL TO \u2014 Customer',
      [
        (_safeStr(inv['customerName'] ?? inv['userName'] ?? inv['name'] ?? data.customerName, '[Customer Name]')).toUpperCase(),
        'Mobile : ${_safeStr(inv['customerMobile'] ?? inv['mobileNumber'] ?? data.customerMobile)}',
        'Email  : ${_safeStr(inv['customerEmail'] ?? inv['email'] ?? data.customerEmail)}',
        'State  : ${_safeStr(inv['stateName'] ?? inv['state'] ?? data.customerState)}',
        'PAN    : ${_safeStr(inv['pan'] ?? inv['panNumber'] ?? data.pan)}',
      ],
    ),
    pw.SizedBox(height: 8),
    _paymentInfo(paymentMethod, paymentRef, paymentDate),
    _sectionBar('Product and charge details'),
    pw.SizedBox(height: 2),
    pw.Container(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(_cGreyL)),
      padding: const pw.EdgeInsets.all(2),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Product: $productLabel  |  HSN Code: $hsnCode', style: _s(7.5)),
        pw.SizedBox(height: 2),
        pw.Text('Live Rate: Rs.${rate.toStringAsFixed(2)} per gram \u2014 fixed at Sale Confirmation', style: _s(7.5)),
        pw.SizedBox(height: 2),
        pw.Text('Quantity purchased: ${qty.toStringAsFixed(4)} grams', style: _s(7.5)),
      ]),
    ),
    pw.SizedBox(height: 4),
    _chargeRow('Base purchase value  (Rate \u00d7 Quantity)', 'Rs. ${gross.toStringAsFixed(2)}', shade: false),
    if (cgstAmt > 0 || sgstAmt > 0) ...[
      _chargeRow('CGST @ ${_safeStr(cgst?['taxPerc'], '1.5')}%', 'Rs. ${cgstAmt.toStringAsFixed(2)}', shade: true),
      _chargeRow('SGST @ ${_safeStr(sgst?['taxPerc'], '1.5')}%', 'Rs. ${sgstAmt.toStringAsFixed(2)}', shade: false),
    ] else ...[
      _chargeRow('IGST @ ${_safeStr(igst?['taxPerc'], '3.0')}%', 'Rs. ${igstAmt.toStringAsFixed(2)}', shade: true),
    ],
    if (discountAmt > 0) _chargeRow('Discount / SuperCoin burn benefit', '- Rs. ${discountAmt.toStringAsFixed(2)}', shade: true),
    if (tcsAmt > 0) _chargeRow('TCS @ applicable rate', 'Rs. ${tcsAmt.toStringAsFixed(2)}', shade: false),
    _chargeRow('TOTAL AMOUNT CHARGED', 'Rs. ${net.toStringAsFixed(2)}', isTotal: true),
    pw.SizedBox(height: 4),
    pw.Text('Amount in words:  ${_toWords(net)}', style: _s(7.5, bold: true)),
    pw.SizedBox(height: 4),
    _balanceRow('GAP account balance after this purchase',
      '${fmt(balanceBefore)} grams', '+ ${fmt(qty)} grams', '${fmt(balanceAfter)} grams'),
    _noticeBox('IRREVOCABLE TRANSACTION',
      'Once Sale Confirmation Ref. $saleConf is issued, this purchase is FINAL, BINDING AND IRREVOCABLE \u2014 it cannot be cancelled or reversed for any reason including price movement. To exit, use the Sale-Back facility (48-hour holding period applies). Augmont Agreement Clause 4.2 | Indian Contract Act 1872 \u00a762',
      _cRedBg, _cRedT),
    _termsBlock(_buyDeclaration, _buyTerms, _regulatoryNotice),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// SELL INVOICE
// ═══════════════════════════════════════════════════════════════════════════

List<pw.Widget> _buildSellInvoice(InvoiceData data) {
  final inv = data.raw;
  final metalType = (inv['metalType'] as String? ?? data.metalType).toUpperCase();
  final metalLabel = metalType == 'SILVER' ? '999 Fine Silver' : '24K 999 Fine Gold';

  final docNo = _safeStr(inv['invoiceNumber'] ?? 'KAR-SBK-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}');
  final docDate = _safeStr(inv['invoiceDate'] ?? inv['sellTransactionDate'] ?? data.date);
  final orderNo = _safeStr(inv['transactionId'] ?? data.transactionId);
  final sbkConf = orderNo;
  final origInv = _safeStr(inv['originalInvoiceRef'] ?? inv['originalInvoiceNumber'] ?? inv['buyInvoiceNumber'] ?? inv['invoiceNumber'] ?? docNo);
  final origDate = _safeStr(inv['originalPurchaseDate'] ?? inv['sellTransactionDate'] ?? '');

  final rate = double.tryParse(inv['rate']?.toString() ?? '') ?? data.rate;
  final qty = double.tryParse(inv['quantity']?.toString() ?? inv['gold']?.toString() ?? '') ?? data.quantity;
  final gross = double.tryParse(inv['grossAmount']?.toString() ?? inv['totalAmount']?.toString() ?? '') ?? data.amount;
  final net = double.tryParse(inv['netAmount']?.toString() ?? inv['payoutAmount']?.toString() ?? inv['totalAmount']?.toString() ?? '') ?? data.totalAmount;
  final tds = double.tryParse(inv['tds']?.toString() ?? '') ?? 0;
  final fee = double.tryParse(inv['convenienceFee']?.toString() ?? '') ?? 0;
  final feeGst = double.tryParse(inv['convenienceFeeGst']?.toString() ?? '') ?? (fee * 0.18);

  final bankAcct = inv['bankAccount'] as Map<String, dynamic>? ?? {};
  final accountNumber = _safeStr(
    inv['accountNumber'] ?? bankAcct['accountNumber'] ?? inv['account_number'] ?? data.bankAccount
  );
  final bankLast4 = accountNumber.length >= 4 ? accountNumber.substring(accountNumber.length - 4) : '';
  final ifsc = _safeStr(
    inv['ifsc'] ?? bankAcct['ifscCode'] ?? bankAcct['ifsc'] ?? inv['ifscCode'] ?? data.ifsc
  );
  final bankName = _safeStr(
    inv['bankName'] ?? bankAcct['bankName'] ?? bankAcct['accountHolderName'] ?? inv['bank_name'] ?? data.bankName
  );

  final paymentRef = _safeStr(inv['paymentRef'] ?? inv['utr'] ?? data.utr);
  final creditDt = _safeStr(inv['paymentDate'] ?? inv['creditDate'] ?? '');

  final balanceBefore = double.tryParse(inv['balanceBefore']?.toString() ?? data.balanceBefore.toString()) ?? data.balanceBefore;
  final balanceAfter = double.tryParse(inv['balanceAfter']?.toString() ?? data.balanceAfter.toString()) ?? data.balanceAfter;

  String fmt(num v) => v.toStringAsFixed(4);

  return [
    _goldBar(),
    pw.SizedBox(height: 6),
    _karatlyHeader(),
    _docTitle('SALE-BACK STATEMENT', 'Cash Redemption \u2014 Proceeds Credited to Bank'),
    _metaBox([
      {'label': 'Document no.              :', 'value': docNo},
      {'label': 'Document date & time      :', 'value': docDate},
      {'label': 'Sale-back order no.       :', 'value': orderNo},
      {'label': 'Sale-back conf. ref.      :', 'value': sbkConf},
      {'label': 'Original purchase inv. ref:', 'value': origInv},
      {'label': 'Original purchase date    :', 'value': '$origDate  \u2014 48-hr lock expired'},
    ]),
    pw.SizedBox(height: 8),
    _partyBox(
      'BUYER \u2014 Repurchaser (Augmont)',
      [_augmontName, _augmontAddress.substring(0, 70), _augmontAddress.substring(70), 'GSTIN: $_augmontGstin  |  PAN: $_augmontPan'],
      'SELLER (CUSTOMER) \u2014 Cash Credit to Bank',
      [
        (_safeStr(inv['customerName'] ?? inv['userName'] ?? inv['name'] ?? data.customerName, '[Customer Name]')).toUpperCase(),
        'Mobile : ${_safeStr(inv['customerMobile'] ?? inv['mobileNumber'] ?? data.customerMobile)}',
        'PAN    : ${_safeStr(inv['pan'] ?? inv['panNumber'] ?? data.pan)}',
        '',
        'Account: XXXX XXXX ${_safeStr(bankLast4, '\u2014\u2014')}',
        'IFSC   : ${_safeStr(ifsc)}',
        'Bank   : ${_safeStr(bankName)}',
      ],
    ),
    pw.SizedBox(height: 8),
    // Transaction snapshot
    _sectionBar('Transaction snapshot'),
    pw.SizedBox(height: 2),
    pw.Row(children: [
      pw.Expanded(child: _snapCol('Metal sold back', metalLabel)),
      pw.Expanded(child: _snapCol('Quantity sold', '${qty.toStringAsFixed(4)} grams')),
      pw.Expanded(child: _snapCol('Sell-back rate', 'Rs.${rate.toStringAsFixed(2)}/gram')),
      pw.Expanded(child: _snapCol('Gross value', 'Rs. ${gross.toStringAsFixed(2)}')),
    ]),
    pw.SizedBox(height: 4),
    // Calculation
    _sectionBar('Calculation \u2014 gross to net payout'),
    pw.SizedBox(height: 2),
    _chargeRow('Gross sale-back value  (${qty.toStringAsFixed(4)} g \u00d7 Rs.${rate.toStringAsFixed(2)}/g)', 'Rs. ${gross.toStringAsFixed(2)}', shade: false),
    _chargeRow('TDS @ 1% deducted at source  (Income Tax Act \u00a7194-O)', '- Rs. ${tds.toStringAsFixed(2)}', shade: true),
    if (fee > 0) ...[
      _chargeRow('Convenience fee', '- Rs. ${fee.toStringAsFixed(2)}', shade: false),
      _chargeRow('GST on convenience fee @ 18%', '- Rs. ${feeGst.toStringAsFixed(2)}', shade: true),
    ],
    _chargeRow('NET PAYOUT TO CUSTOMER', 'Rs. ${net.toStringAsFixed(2)}', isTotal: true),
    pw.SizedBox(height: 4),
    pw.Text('Credited to: $bankName A/c ending $bankLast4  |  UTR: $paymentRef  |  Date: $creditDt', style: _s(7, color: 0xFF3C3C3C)),
    pw.SizedBox(height: 2),
    pw.Text('Amount in words:  ${_toWords(net)}', style: _s(7.5, bold: true)),
    pw.SizedBox(height: 4),
    _balanceRow('GAP account \u2014 gold / silver debited on sale-back',
      '${fmt(balanceBefore)} grams', '- ${fmt(qty)} grams', '${fmt(balanceAfter)} grams', isNegative: true),
    _noticeBox('48-HOUR HOLDING PERIOD CONFIRMED',
      'This Sale-Back Order was placed after the mandatory 48-hour holding period from original purchase ($origDate). Karatly enforced this at transaction level. [Augmont Agreement Clauses 8.1, 14.6]',
      _cBluBg, _cBluT),
    _noticeBox('REGISTERED BANK ACCOUNT CREDIT ONLY',
      'Proceeds of Rs.${net.toStringAsFixed(2)} credited exclusively to Customer\'s registered bank account. Cannot be directed to any third-party account. [Clause 8.3 | RBI PA Guidelines]',
      _cGrnBg, _cGrnT),
    _noticeBox('TITLE TRANSFER \u2014 FINAL',
      'Title of the Gold / Silver described above has passed from ${_safeStr(inv['customerName'] ?? inv['userName'] ?? inv['name'] ?? data.customerName, 'Customer')} to Augmont Goldtech Private Limited at Sale-Back Confirmation (Ref: $sbkConf). This transaction is final. [Clause 8.4 | Indian Contract Act 1872 \u00a762]',
      _cRedBg, _cRedT),
    _termsBlock(_sellDeclaration, _sellTerms, _regulatoryNotice),
  ];
}

pw.Widget _snapCol(String label, String value) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(_cGreyL),
      border: pw.Border.all(color: PdfColor.fromInt(_cGreyM), width: 0.15),
    ),
    padding: const pw.EdgeInsets.all(1),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: _s(6.5, bold: true, color: 0xFF505050)),
      pw.SizedBox(height: 3),
      pw.Text(value, style: _s(8, bold: true)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// REDEEM INVOICE
// ═══════════════════════════════════════════════════════════════════════════

List<pw.Widget> _buildRedeemInvoice(InvoiceData data) {
  final inv = data.raw;

  final invoiceNo = _safeStr(inv['invoiceNumber'] ?? 'KAR-RDM-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}');
  final invoiceDate = _safeStr(inv['invoiceDate'] ?? data.date);
  final orderNo = _safeStr(inv['transactionId'] ?? data.transactionId);
  final rdmConf = _safeStr(inv['rdmConfRef'] ?? inv['augmontRef'] ?? '');
  final dispatch = _safeStr(inv['expectedDispatch'] ?? '');
  final courier = _safeStr(inv['courierTracking'] ?? '');

  final productName = _safeStr(inv['productName'] ?? 'Gold Coin / Silver Coin / Gold Bar');
  final qty = double.tryParse(inv['quantity']?.toString() ?? '') ?? data.quantity;
  final gross = double.tryParse(inv['grossAmount']?.toString() ?? inv['totalAmount']?.toString() ?? '') ?? data.amount;
  final total = double.tryParse(inv['netAmount']?.toString() ?? inv['totalAmount']?.toString() ?? '') ?? data.totalAmount;
  final making = double.tryParse(inv['makingCharges']?.toString() ?? '') ?? 0;
  final makGst = double.tryParse(inv['makingGst']?.toString() ?? '') ?? (making * 0.05);
  final delivery = double.tryParse(inv['deliveryCharges']?.toString() ?? '') ?? 0;
  final delGst = double.tryParse(inv['deliveryGst']?.toString() ?? '') ?? (delivery * 0.18);
  final unitPrice = double.tryParse(inv['unitPrice']?.toString() ?? inv['rate']?.toString() ?? '') ?? data.rate;

  final paymentMethod = _safeStr(inv['paymentMethod'] ?? inv['paymentMode'] ?? data.paymentMethod, 'UPI');
  final paymentRef = _safeStr(inv['paymentRef'] ?? data.transactionId);
  final paymentDate = _safeStr(inv['paymentDate'] ?? inv['invoiceDate'] ?? data.date);

  final balanceBefore = double.tryParse(inv['balanceBefore']?.toString() ?? data.balanceBefore.toString()) ?? data.balanceBefore;
  final balanceAfter = double.tryParse(inv['balanceAfter']?.toString() ?? data.balanceAfter.toString()) ?? data.balanceAfter;

  final discount = inv['discount'];
  double discountAmt = 0;
  if (discount is Map) {
    discountAmt = double.tryParse((discount['amount'] ?? discount['value'] ?? 0).toString()) ?? 0;
  } else {
    discountAmt = double.tryParse(discount?.toString() ?? '') ?? 0;
  }

  final delName = _safeStr(inv['deliveryName'] ?? inv['customerName'] ?? data.customerName);
  final delAddress1 = _safeStr(inv['deliveryAddress'] ?? inv['address'] ?? data.address);
  final delCity = _safeStr(inv['deliveryCity'] ?? inv['city'] ?? '');
  final delState = _safeStr(inv['deliveryState'] ?? inv['state'] ?? '');
  final delPincode = _safeStr(inv['deliveryPincode'] ?? inv['pincode'] ?? '');
  final delMobile = _safeStr(inv['deliveryMobile'] ?? inv['mobileNumber'] ?? data.customerMobile);

  String fmt(num v) => v.toStringAsFixed(4);

  return [
    _goldBar(),
    pw.SizedBox(height: 6),
    _karatlyHeader(),
    _docTitle('TAX INVOICE', 'Physical Redemption / Delivery'),
    _metaBox([
      {'label': 'Invoice no.            :', 'value': invoiceNo},
      {'label': 'Invoice date & time    :', 'value': invoiceDate},
      {'label': 'Redemption order no.   :', 'value': orderNo},
      {'label': 'Redemption conf. ref.  :', 'value': rdmConf},
      {'label': 'Expected dispatch date :', 'value': '$dispatch  (SLA: 1\u20134 Business Days)'},
      {'label': 'Courier tracking no.   :', 'value': courier},
    ]),
    pw.SizedBox(height: 8),
    _partyBox(
      'ISSUED BY (Seller)',
      [_augmontName, _augmontAddress.substring(0, 70), _augmontAddress.substring(70), 'GSTIN: $_augmontGstin  |  PAN: $_augmontPan'],
      'DELIVER TO',
      [
        delName.toUpperCase(),
        delAddress1,
        '${delCity}, ${delState} \u2013 ${delPincode}',
        'Mobile: $delMobile',
      ],
    ),
    pw.SizedBox(height: 8),
    _paymentInfo(paymentMethod, paymentRef, paymentDate),
    _sectionBar('Product details'),
    pw.SizedBox(height: 2),
    pw.Container(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(_cGreyL)),
      padding: const pw.EdgeInsets.all(2),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Product: $productName  |  Purity: 999 Fine', style: _s(7.5)),
        pw.SizedBox(height: 2),
        pw.Text('BIS HUID: ${_safeStr(inv['bisHuid'])}  |  Serial No.: ${_safeStr(inv['serialNo'])}  |  Qty: ${qty.toInt()} unit(s)', style: _s(7.5)),
        pw.SizedBox(height: 2),
        pw.Text('HSN Code: ${_safeStr(inv['hsnCode'], '7108')}  |  Unit Price: Rs.${unitPrice.toStringAsFixed(2)}', style: _s(7.5)),
      ]),
    ),
    pw.SizedBox(height: 4),
    _sectionBar('Charge breakup \u2014 making, delivery and taxes'),
    pw.SizedBox(height: 2),
    _chargeRow('Gold / Silver spot value (reference \u2014 already paid at purchase)', 'Rs. ${gross.toStringAsFixed(2)}', shade: false),
    _chargeRow('Making / manufacturing charges', 'Rs. ${making.toStringAsFixed(2)}', shade: true),
    _chargeRow('GST on making charges @ 5%', 'Rs. ${makGst.toStringAsFixed(2)}', shade: false),
    _chargeRow('Delivery / courier charges', 'Rs. ${delivery.toStringAsFixed(2)}', shade: true),
    _chargeRow('GST on delivery charges @ 18%', 'Rs. ${delGst.toStringAsFixed(2)}', shade: false),
    if (discountAmt > 0) _chargeRow('Discount', '- Rs. ${discountAmt.toStringAsFixed(2)}', shade: true),
    _chargeRow('TOTAL AMOUNT CHARGED FOR REDEMPTION', 'Rs. ${total.toStringAsFixed(2)}', isTotal: true),
    pw.SizedBox(height: 4),
    pw.Text('Amount in words:  ${_toWords(total)}', style: _s(7.5, bold: true)),
    pw.SizedBox(height: 4),
    _balanceRow('GAP account \u2014 gold / silver debited on this redemption',
      '${fmt(balanceBefore)} grams', '- ${fmt(qty)} grams', '${fmt(balanceAfter)} grams', isNegative: true),
    _noticeBox('DELIVERY SLA',
      'Coins and standard products dispatched within 1 Business Day. Other products within 4 Business Days. Augmont-Bullion is fully responsible for the product until delivery. [Clauses 7.4, 7.7.2]',
      _cBluBg, _cBluT),
    _noticeBox('7-DAY COMPLAINT WINDOW',
      'Any complaint regarding quantity, weight, quality, purity, condition, or incorrect shipment must be raised within 7 days from delivery. After this period complaints will NOT be entertained. Raise at support@karatly.net with Invoice No. and photographs. [Consumer Protection Act 2019]',
      _cRedBg, _cRedT),
    _termsBlock(_redeemDeclaration, _redeemTerms, _regulatoryNotice),
  ];
}
