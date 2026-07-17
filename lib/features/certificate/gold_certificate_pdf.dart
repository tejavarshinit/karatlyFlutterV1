import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img_lib;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'certificate_service.dart';

String _fmt(num v, int d) => v.toStringAsFixed(d);

late pw.Font _regularFont;
late pw.Font _boldFont;

pw.TextStyle _s(double fontSize, {bool bold = false, int color = 0xFF000000, double? letterSpacing, double? lineSpacing}) {
  return pw.TextStyle(
    font: bold ? _boldFont : _regularFont,
    fontSize: fontSize,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: PdfColor.fromInt(color),
    letterSpacing: letterSpacing,
    lineSpacing: lineSpacing,
  );
}

Future<Uint8List> generateGoldCertificatePdf(CertificateData data) async {
  final reg = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final bld = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  _regularFont = pw.Font.ttf(reg);
  _boldFont = pw.Font.ttf(bld);

  final doc = pw.Document();

  Uint8List? sigBytes;
  Uint8List? stampBytes;
  try {
    final sigRaw = (await rootBundle.load('assets/images/certificate/signature.png')).buffer.asUint8List();
    final stampRaw = (await rootBundle.load('assets/images/certificate/stamp.png')).buffer.asUint8List();
    sigBytes = _compressImage(sigRaw, height: 40);
    stampBytes = _compressImage(stampRaw, height: 56);
  } catch (_) {}

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        _header(),
        pw.SizedBox(height: 16),
        _titleCard(),
        pw.SizedBox(height: 16),
        _infoRow(data),
        pw.SizedBox(height: 16),
        _customerPortfolioSection(data),
        pw.SizedBox(height: 16),
        _latestPurchaseHoldingSection(data),
        pw.SizedBox(height: 16),
        _historyTable(data),
        pw.SizedBox(height: 16),
        _highlights(),
        pw.SizedBox(height: 16),
        _noteVerification(data),
        pw.SizedBox(height: 24),
        if (sigBytes != null && stampBytes != null)
          _signatureStamp(sigBytes!, stampBytes!),
        pw.SizedBox(height: 16),
        _footer(),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Row(
        children: [
          pw.Container(
            width: 48, height: 48,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFD3B868)),
              color: PdfColor.fromInt(0x21F5E0A0),
            ),
            child: pw.Center(child: pw.Text('K', style: _s(22, bold: true, color: 0xFFB68611))),
          ),
          pw.SizedBox(width: 12),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('KARATLY', style: _s(20, bold: true, letterSpacing: 2, color: 0xFF9A7800)),
            pw.Text('Digital Gold \u00b7 Silver \u00b7 Diamonds', style: _s(9, letterSpacing: 2, color: 0xFF6B5F40)),
          ]),
        ],
      ),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('Powered by', style: _s(9, letterSpacing: 2, color: 0xFF1F2937)),
        pw.Text('AUGMONT', style: _s(14, bold: true, color: 0xFF0F1720)),
        pw.Text('Gold for All', style: _s(8, letterSpacing: 2, color: 0xFF6B7280)),
      ]),
    ],
  );
}

pw.Widget _titleCard() {
  return pw.Container(
    padding: pw.EdgeInsets.all(20),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F2E6),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE2C77A)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(children: [
      pw.Text('OVERALL DIGITAL GOLD', style: _s(16, bold: true, letterSpacing: 3, color: 0xFF111827)),
      pw.Text('HOLDING CERTIFICATE', style: _s(16, bold: true, letterSpacing: 3, color: 0xFF111827)),
      pw.SizedBox(height: 6),
      pw.Text('Your gold. Secure today. Wealth for tomorrow.', style: _s(10, letterSpacing: 2, color: 0xFF6B7280)),
    ]),
  );
}

pw.Widget _infoRow(CertificateData data) {
  return pw.Row(children: [
    pw.Expanded(child: _infoBox('Certificate No.', data.certificateNumber)),
    pw.SizedBox(width: 8),
    pw.Expanded(child: _infoBox('Date of Issue', data.issueDate)),
    pw.SizedBox(width: 8),
    pw.Expanded(child: _infoBox('Certificate Type', data.certificateType)),
  ]);
}

pw.Widget _infoBox(String label, String value) {
  return pw.Container(
    padding: pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFFDF9F4),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(14),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: _s(9, letterSpacing: 2, color: 0xFF000000)),
      pw.SizedBox(height: 4),
      pw.Text(value, style: _s(11, bold: true, color: 0xFF000000)),
    ]),
  );
}

pw.Widget _customerPortfolioSection(CertificateData data) {
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(child: _customerInfo(data)),
    pw.SizedBox(width: 12),
    pw.Expanded(child: _portfolioBadges(data)),
  ]);
}

pw.Widget _customerInfo(CertificateData data) {
  return pw.Container(
    padding: pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F6F0),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Customer Information', style: _s(10, bold: true, letterSpacing: 2, color: 0xFF000000)),
      pw.SizedBox(height: 12),
      _kv('Customer Name', data.customer.name),
      _kv('Customer ID', data.customer.customerId),
      _kv('Registered Mobile', data.customer.mobileNumber),
      _kv('Email Address', data.customer.email),
      _kv('PAN (Masked)', data.customer.panMasked),
    ]),
  );
}

pw.Widget _kv(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: _s(9, color: 0xFF000000)),
      pw.Text(value, style: _s(9, color: 0xFF000000)),
    ]),
  );
}

pw.Widget _portfolioBadges(CertificateData data) {
  final p = data.portfolio;
  String f4(num v) => _fmt(v, 4);
  String f2(num v) => _fmt(v, 2);
  return pw.Container(
    padding: pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F6F0),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Overall Gold Portfolio', style: _s(10, bold: true, letterSpacing: 2, color: 0xFF000000)),
      pw.SizedBox(height: 12),
      _badge('Total Portfolio (g)', '${f4(p.totalGoldPortfolioGrams)} g'),
      _badge('Total Portfolio (Value)', '\u20b9${f2(p.totalGoldPortfolioValue)}'),
      _badge('Total Redeem/Sold (g)', '${f4(p.totalDigitalGoldRedeemSold)} g'),
      _badge('Current Gold Rate', '\u20b9${f2(p.currentGoldRate)}/g'),
    ]),
  );
}

pw.Widget _badge(String label, String value) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 4),
    padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xCC0F1720),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(children: [
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: _s(7, bold: true, color: 0xFFFFFFFF)),
        pw.Text(value, style: _s(7, color: 0xFFFFFFFF)),
      ])),
    ]),
  );
}

pw.Widget _latestPurchaseHoldingSection(CertificateData data) {
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(child: _latestPurchaseCard(data)),
    pw.SizedBox(width: 12),
    pw.Expanded(child: _holdingSummaryCard(data)),
  ]);
}

pw.Widget _latestPurchaseCard(CertificateData data) {
  final lp = data.latestPurchase;
  String f4(num v) => _fmt(v, 4);
  String f2(num v) => _fmt(v, 2);
  return pw.Container(
    padding: pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F6F0),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Latest Purchase Summary', style: _s(10, bold: true, letterSpacing: 2, color: 0xFF0F1720)),
      pw.SizedBox(height: 12),
      _kv('Latest Transaction ID', lp.transactionId),
      _kv('Purchase Date', lp.purchaseDate),
      _kv('Purchase Time', lp.purchaseTime),
      _kv('Quantity Purchased', '${f4(lp.quantity)} g'),
      _kv('Gold Rate', '\u20b9${f2(lp.rate)}/g'),
      _kv('Investment Amount', '\u20b9${f2(lp.amount)}'),
      _kv('Payment Method', lp.paymentMethod),
      _kv('Payment Status', lp.paymentStatus),
    ]),
  );
}

pw.Widget _holdingSummaryCard(CertificateData data) {
  final hs = data.holdingSummary;
  String f4(num v) => _fmt(v, 4);
  return pw.Container(
    padding: pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F6F0),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Gold Holding Summary', style: _s(10, bold: true, letterSpacing: 2, color: 0xFF0F1720)),
      pw.SizedBox(height: 12),
      _kv('Total Gold Portfolio (g)', '${f4(hs.totalGoldPortfolio)} g'),
      _kv('Total Digital Gold Redeem/Sold (g)', '${f4(hs.totalDigitalGoldRedeemSold)} g'),
      _kv('Available for Redemption (g)', '${f4(hs.availableForRedemption)} g'),
      _kv('Vault Storage', hs.vaultStorage),
      _kv('Gold Purity', hs.goldPurity),
      _kv('Storage Partner', hs.storagePartner),
      _kv('Insurance Coverage', hs.insuranceCoverage),
    ]),
  );
}

pw.Widget _historyTable(CertificateData data) {
  String f4(num v) => _fmt(v, 4);
  String f2(num v) => _fmt(v, 2);
  return pw.Container(
    padding: pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F6F0),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Purchase History', style: _s(10, bold: true, letterSpacing: 2, color: 0xFF111827)),
      pw.SizedBox(height: 8),
      pw.Row(children: [
        pw.Expanded(child: pw.Text('Date', style: _s(7, bold: true, color: 0xFF000000))),
        pw.Expanded(flex: 2, child: pw.Text('Transaction ID', style: _s(7, bold: true, color: 0xFF000000))),
        pw.Expanded(child: pw.Text('Qty (g)', style: _s(7, bold: true, color: 0xFF000000))),
        pw.Expanded(child: pw.Text('Rate/g', style: _s(7, bold: true, color: 0xFF000000))),
        pw.Expanded(child: pw.Text('Amount', style: _s(7, bold: true, color: 0xFF000000))),
        pw.Expanded(child: pw.Text('Status', style: _s(7, bold: true, color: 0xFF000000))),
      ]),
      pw.Divider(color: PdfColor.fromInt(0xFFE7D4A9)),
      ...data.purchaseHistory.map((item) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(item.date, style: _s(7))),
          pw.Expanded(flex: 2, child: pw.Text(item.transactionId, style: _s(7))),
          pw.Expanded(child: pw.Text(f4(item.quantity), style: _s(7))),
          pw.Expanded(child: pw.Text('\u20b9${f2(item.rate)}', style: _s(7))),
          pw.Expanded(child: pw.Text('\u20b9${f2(item.amount)}', style: _s(7))),
          pw.Expanded(child: pw.Text(item.status, style: _s(7, color: 0xFF10B981))),
        ]),
      )),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child:         pw.Text('Latest 5 Transactions', style: _s(8, color: 0xFF000000)),
      ),
    ]),
  );
}

pw.Widget _highlights() {
  return pw.Row(children: [
    pw.Expanded(child: _hlCard('24K (999.9)', 'Pure Gold')),
    pw.SizedBox(width: 8),
    pw.Expanded(child: _hlCard('Secure Vault Storage', 'Stored in secure insured vaults')),
    pw.SizedBox(width: 8),
    pw.Expanded(child: _hlCard('Fully Insured', 'Your holdings are fully insured at every stage')),
  ]);
}

pw.Widget _hlCard(String title, String subtitle) {
  return pw.Container(
    padding: pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8F6F0),
      border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Column(children: [
      pw.Text(title, style: _s(10, bold: true, color: 0xFF000000)),
      pw.SizedBox(height: 4),
      pw.Text(subtitle, style: _s(8, color: 0xFF000000)),
    ]),
  );
}

pw.Widget _noteVerification(CertificateData data) {
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(flex: 3, child: pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8F6F0),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Text(data.certificateNote, style: _s(8, lineSpacing: 1.6, color: 0xFF000000)),
    )),
    pw.SizedBox(width: 8),
    pw.Expanded(flex: 2, child: pw.Column(children: [
      pw.Container(
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF8F6F0),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE8D7A6)),
          borderRadius: pw.BorderRadius.circular(16),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Verification', style: _s(10, bold: true, color: 0xFF111827)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFFFFF),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFDCC082)),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Scan to Verify Certificate', style: _s(7, bold: true, color: 0xFF000000)),
              pw.Text('Verification URL', style: _s(7, color: 0xFF000000)),
              pw.Text(data.verificationUrl, style: _s(7, bold: true, color: 0xFF000000)),
              pw.SizedBox(height: 4),
              pw.Text('Verification Hash', style: _s(7, color: 0xFF000000)),
              pw.Text(data.verificationHash, style: _s(7, bold: true, color: 0xFF000000)),
            ]),
          ),
        ]),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFFEF8E4),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFDCC082)),
          borderRadius: pw.BorderRadius.circular(16),
        ),
        child: pw.Column(children: [
          pw.Text('Authorized by', style: _s(8, color: 0xFF000000)),
          pw.Text('Karatly', style: _s(12, bold: true, color: 0xFF000000)),
          pw.Text('Powered by Augmont', style: _s(7, letterSpacing: 2, color: 0xFF000000)),
        ]),
      ),
    ])),
  ]);
}

pw.Widget _signatureStamp(Uint8List sigBytes, Uint8List stampBytes) {
  final sigImg = pw.Image(pw.MemoryImage(sigBytes), height: 40, fit: pw.BoxFit.contain);
  final stampImg = pw.Image(pw.MemoryImage(stampBytes), height: 56, fit: pw.BoxFit.contain);
  return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
    pw.Column(children: [
      sigImg,
      pw.Text('Authorised Signatory', style: _s(8, letterSpacing: 1, color: 0xFF000000)),
    ]),
    pw.Column(children: [
      stampImg,
      pw.Text('Karatly Finvest Technology India Private Limited', style: _s(8, letterSpacing: 1, color: 0xFF000000)),
    ]),
  ]);
}

pw.Widget _footer() {
  return pw.Container(
    padding: pw.EdgeInsets.only(top: 12),
    decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE8D7A6)))),
    child: pw.Column(children: [
      pw.Text('Customer Support', style: _s(8, bold: true, color: 0xFF000000)),
      pw.SizedBox(height: 4),
      pw.Text('Phone: +91 93929 18025  |  Email: support@karatly.com  |  Website: www.karatly.net', style: _s(7, color: 0xFF000000)),
    ]),
  );
}

Uint8List _compressImage(Uint8List raw, {int height = 40}) {
  img_lib.Image? original = img_lib.decodeImage(raw);
  if (original == null) return raw;
  final ratio = height / original.height;
  final width = (original.width * ratio).round();
  final resized = img_lib.copyResize(original, width: width, height: height);
  return Uint8List.fromList(img_lib.encodeJpg(resized, quality: 85));
}
