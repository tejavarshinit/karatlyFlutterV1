import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../certificate/certificate_service.dart';
import '../certificate/gold_certificate_pdf.dart';

class GoldCertificateScreen extends StatefulWidget {
  const GoldCertificateScreen({super.key});

  @override
  State<GoldCertificateScreen> createState() => _GoldCertificateScreenState();
}

class _GoldCertificateScreenState extends State<GoldCertificateScreen> {
  CertificateData? _certificate;
  bool _loading = true;
  String? _error;
  bool _downloading = false;
  double _scale = 1;
  bool _fitToScreen = true;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await getCertificate();
      if (result['ok'] == true && mounted) {
        setState(() { _certificate = result['certificate'] as CertificateData?; _loading = false; });
      } else {
        setState(() { _error = result['message']?.toString() ?? 'Unable to load certificate details.'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Unable to load certificate details. Please try again.'; _loading = false; });
    }
  }

  Future<void> _downloadPdf() async {
    if (_certificate == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final pdfBytes = await generateGoldCertificatePdf(_certificate!);
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/Gold-Certificate-${_certificate!.certificateNumber}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Gold Certificate - ${_certificate!.certificateNumber}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download certificate')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.97, -0.38),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1AFFFFFF)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Gold Purchase Certificate', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
              if (_certificate != null && !_loading) _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF7CD57)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCertificate,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7CD57), foregroundColor: Colors.black),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_certificate == null) {
      return const Center(child: Text('No certificate data available.', style: TextStyle(color: Color(0xFF9E9A94))));
    }
    return InteractiveViewer(
      maxScale: 3,
      minScale: 0.3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    final d = _certificate!;
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5B264)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD3B868)), color: const Color(0xFFF5E0A0).withOpacity(0.13)),
                child: const Center(child: Text('K', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB68611))))),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('KARATLY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF9A7800))),
                Text('Digital Gold · Silver · Diamonds', style: TextStyle(fontSize: 8, letterSpacing: 1, color: const Color(0xFF6B5F40))),
              ]),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Powered by', style: TextStyle(fontSize: 8, color: Color(0xFF1F2937))),
              const SizedBox(height: 2),
              const Text('AUGMONT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F1720))),
              Text('Gold for All', style: TextStyle(fontSize: 7, letterSpacing: 1, color: const Color(0xFF6B7280))),
            ]),
          ]),
          const SizedBox(height: 12),
          // Title
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8F2E6), border: Border.all(color: const Color(0xFFE2C77A)), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              const Text('OVERALL DIGITAL GOLD\nHOLDING CERTIFICATE', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF111827))),
              const SizedBox(height: 4),
              Text('Your gold. Secure today. Wealth for tomorrow.',
                  style: TextStyle(fontSize: 8, letterSpacing: 1, color: const Color(0xFF6B7280))),
            ]),
          ),
          const SizedBox(height: 12),
          // Info row
          Row(children: [
            Expanded(child: _previewInfoCard('Certificate No.', d.certificateNumber)),
            const SizedBox(width: 8),
            Expanded(child: _previewInfoCard('Date of Issue', d.issueDate)),
            const SizedBox(width: 8),
            Expanded(child: _previewInfoCard('Certificate Type', d.certificateType)),
          ]),
        ],
      ),
    );
  }

  Widget _previewInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFFDF9F4), border: Border.all(color: const Color(0xFFE8D7A6)), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 7, letterSpacing: 1, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF231D14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            onPressed: () { setState(() { _fitToScreen = false; _scale = (_scale - 0.1).clamp(0.35, 1.5); }); },
          ),
          TextButton(
            onPressed: () => setState(() { _fitToScreen = true; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF7CD57), borderRadius: BorderRadius.circular(20)),
              child: const Text('Fit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            onPressed: () { setState(() { _fitToScreen = false; _scale = (_scale + 0.1).clamp(0.35, 1.5); }); },
          ),
          const Spacer(),
          GestureDetector(
            onTap: _downloadPdf,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF7CD57), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_downloading ? Icons.hourglass_top : Icons.download, size: 14, color: Colors.black),
                const SizedBox(width: 6),
                Text(_downloading ? 'Downloading...' : 'Download PDF',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
