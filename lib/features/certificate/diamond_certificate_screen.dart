import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import 'certificate_service.dart';
import 'diamond_certificate_pdf.dart';
import 'download_helper.dart';

class DiamondCertificateScreen extends StatefulWidget {
  const DiamondCertificateScreen({super.key});

  @override
  State<DiamondCertificateScreen> createState() => _DiamondCertificateScreenState();
}

class _DiamondCertificateScreenState extends State<DiamondCertificateScreen> {
  DiamondCertificateData? _cert;
  bool _loading = true;
  String? _error;
  bool _downloading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await getDiamondCertificate();
      if (r['ok'] == true && mounted) {
        setState(() { _cert = r['certificate'] as DiamondCertificateData?; _loading = false; });
      } else { setState(() { _error = r['message']?.toString() ?? 'Failed to load'; _loading = false; }); }
    } catch (_) { if (mounted) setState(() { _error = 'Unable to load certificate.'; _loading = false; }); }
  }

  Future<void> _downloadPdf() async {
    if (_cert == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final pdfBytes = await generateDiamondCertificatePdf(_cert!);
      await downloadPdf(pdfBytes, 'Diamond-Certificate-${_cert!.certificateNumber}.pdf');
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed'))); }
    finally { if (mounted) setState(() => _downloading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0.97, -0.38), radius: 1.04, colors: [Color(0xFF1E1B4B), Color(0xFF0F0F23)])),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(children: [
                GestureDetector(onTap: () => context.go(AppRoutes.home), child: Container(width: 36, height: 36, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1AFFFFFF)), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC7D2FE), size: 18))),
                const SizedBox(width: 8),
                const Text('Diamond Purchase Certificate', style: TextStyle(fontSize: 14, color: Color(0xFFC7D2FE))),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC7D2FE)))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC7D2FE), foregroundColor: Colors.black), child: const Text('Retry')),
                      ])))
                    : _cert == null
                        ? const Center(child: Text('No certificate data.', style: TextStyle(color: Color(0xFFA5B4FC))))
                        : InteractiveViewer(maxScale: 3, minScale: 0.3, child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildPreview()))),
            if (_cert != null && !_loading) _buildBottomBar(),
          ]),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final d = _cert!;
    return Container(
      width: 400, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFA5B4FC))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 12),
        _titleCard(),
        const SizedBox(height: 12),
        _infoRow(d),
        const SizedBox(height: 12),
        _customerInfo(d),
        const SizedBox(height: 12),
        _investmentSummary(d),
        const SizedBox(height: 12),
        _orderHistory(d),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _hlCard('Certified Diamond', 'GIA / IGI certified')),
          const SizedBox(width: 8),
          Expanded(child: _hlCard('Insured Shipping', 'Fully insured delivery')),
          const SizedBox(width: 8),
          Expanded(child: _hlCard('100% Verified', 'Authenticity guaranteed')),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: _noteCard(d.certificateNote)), const SizedBox(width: 8),
          Expanded(flex: 2, child: Column(children: [
            _verificationCard(d), const SizedBox(height: 8), _authorizedCard(),
          ])),
        ]),
        const SizedBox(height: 16), _signatureStamp(), const SizedBox(height: 8), _footerLine(),
      ]),
    );
  }

  Widget _header() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA5B4FC)), color: const Color(0xFFEEF2FF).withOpacity(0.5)), child: const Center(child: Text('K', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))))),
        const SizedBox(width: 8),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KARATLY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black)),
          Text('Digital Gold · Silver · Diamonds', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.black)),
        ]),
      ]),
      const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('Powered by', style: TextStyle(fontSize: 8, letterSpacing: 2, color: Colors.black54)),
        Text('AUGMONT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        Text('Diamonds for All', style: TextStyle(fontSize: 7, letterSpacing: 2, color: Colors.black54)),
      ]),
    ]);
  }

  Widget _titleCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(12)),
      child: const Column(children: [
        Text('DIAMOND PURCHASE\nCERTIFICATE', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87)),
        SizedBox(height: 4),
        Text('Your diamond. Certified. Eternal.', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.black54)),
      ]));
  }

  Widget _infoRow(DiamondCertificateData d) {
    return Column(children: [
      Row(children: [
        Expanded(child: _infoCard('Certificate No.', d.certificateNumber)), const SizedBox(width: 8),
        Expanded(child: _infoCard('Date of Issue', d.issueDate)),
      ]), const SizedBox(height: 8),
      _infoCard('Certificate Type', d.certificateType, fullWidth: true),
    ]);
  }

  Widget _infoCard(String label, String value, {bool fullWidth = false}) {
    return Container(width: fullWidth ? double.infinity : null, padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.black54)),
        const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]));
  }

  Widget _customerInfo(DiamondCertificateData d) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFF1E1B4B), borderRadius: BorderRadius.circular(13)),
            child: const Center(child: Icon(Icons.person, color: Color(0xFFC7D2FE), size: 14))),
          const SizedBox(width: 8), const Text('Customer Information', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
        ]),
        const SizedBox(height: 10),
        _kv('Customer Name', d.customer.name), _kv('Customer ID', d.customer.customerId),
        _kv('Registered Mobile', d.customer.mobileNumber), _kv('Email Address', d.customer.email),
        _kv('PAN (Masked)', d.customer.panMasked),
      ]));
  }

  Widget _kv(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 9, color: Colors.black87), textAlign: TextAlign.right)),
      ]));
  }

  Widget _investmentSummary(DiamondCertificateData d) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(color: const Color(0xFF1E1B4B), borderRadius: BorderRadius.circular(13)),
            child: const Center(child: Icon(Icons.diamond, color: Color(0xFFC7D2FE), size: 14))),
          const SizedBox(width: 8), const Text('Investment Summary', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
        ]),
        const SizedBox(height: 10),
        _kv('Total Investment', d.totalInvestment),
        _kv('Total Orders', d.totalOrders.toString()),
        _kv('Payment Partner', 'Cashfree'),
        _kv('Certification', 'GIA / IGI'),
        _kv('Shipping', 'Insured & Tracked'),
        _kv('Authenticity', '100% Verified'),
      ]));
  }

  Widget _orderHistory(DiamondCertificateData d) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Order History', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFC7D2FE)))),
          child: const Row(children: [
            Expanded(child: Text('Date', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Expanded(flex: 2, child: Text('Transaction ID', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Expanded(child: Text('Diamond', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Expanded(child: Text('Amount', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Expanded(child: Text('Status', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
          ])),
        ...d.orderHistory.map((item) => Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x61C7D2FE)))),
          child: Row(children: [
            Expanded(child: Text(item.date, style: const TextStyle(fontSize: 7, color: Colors.black))),
            Expanded(flex: 2, child: Text(item.transactionId, style: const TextStyle(fontSize: 7, color: Colors.black))),
            Expanded(child: Text(item.diamond, style: const TextStyle(fontSize: 7, color: Colors.black))),
            Expanded(child: Text(item.amount, style: const TextStyle(fontSize: 7, color: Colors.black))),
            Expanded(child: Text(item.status, style: const TextStyle(fontSize: 7, color: Color(0xFF10B981)))),
          ]))),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: Text('Latest Orders', style: const TextStyle(fontSize: 8, color: Colors.black54))),
      ]));
  }

  Widget _hlCard(String title, String subtitle) {
    return Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
        const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 7, color: Colors.black54)),
      ]));
  }

  Widget _noteCard(String note) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(14)),
      child: Text(note, style: const TextStyle(fontSize: 9, color: Colors.black54, height: 1.5)));
  }

  Widget _verificationCard(DiamondCertificateData d) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Verification', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 10),
        Container(width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Scan to Verify Certificate', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 6),
            _kv('Verification URL', d.verificationUrl),
            _kv('Verification Hash', d.verificationHash),
          ])),
      ]));
  }

  Widget _authorizedCard() {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), border: Border.all(color: const Color(0xFFC7D2FE)), borderRadius: BorderRadius.circular(14)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Authorized by', style: TextStyle(fontSize: 8, color: Colors.black54)),
        SizedBox(height: 6), Text('Karatly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('Powered by Augmont', style: TextStyle(fontSize: 7, letterSpacing: 1, color: Colors.black54)),
      ]));
  }

  Widget _signatureStamp() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Column(children: [
        Image.asset('assets/images/certificate/signature.png', height: 45, fit: BoxFit.contain),
        const SizedBox(height: 6), const Text('Authorised Signatory', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.black54)),
      ]),
      Column(children: [
        Image.asset('assets/images/certificate/stamp.png', height: 60, fit: BoxFit.contain),
        const SizedBox(height: 6), const Text('Karatly Finvest Technology\nIndia Private Limited', textAlign: TextAlign.center, style: TextStyle(fontSize: 7, letterSpacing: 1, color: Colors.black54)),
      ]),
    ]);
  }

  Widget _footerLine() {
    return Column(children: [
      const Divider(color: Color(0xFFE0E7FF)),
      const SizedBox(height: 8), const Text('Customer Support', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 4), const Text('Phone: +91 93929 18025  |  Email: support@karatly.com  |  Website: www.karatly.net', style: TextStyle(fontSize: 7, color: Colors.black54)),
    ]);
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E1B4B), borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(
          onTap: _downloadPdf,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFC7D2FE), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_downloading ? Icons.hourglass_top : Icons.download, size: 14, color: Colors.black),
              const SizedBox(width: 6),
              Text(_downloading ? 'Downloading...' : 'Download PDF', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}
