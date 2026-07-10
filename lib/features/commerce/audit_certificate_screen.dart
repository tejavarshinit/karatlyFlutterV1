import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../certificate/audit_certificate_pdf.dart';

class AuditCertificateScreen extends StatefulWidget {
  const AuditCertificateScreen({super.key});

  @override
  State<AuditCertificateScreen> createState() => _AuditCertificateScreenState();
}

class _AuditCertificateScreenState extends State<AuditCertificateScreen> {
  double _scale = 1;
  bool _downloading = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/certificate/audit_certificate.jpg');
    if (mounted) setState(() => _imageBytes = data.buffer.asUint8List());
  }

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final pdfBytes = await generateAuditCertificatePdf();
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/Audit-Certificate.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Audit Certificate');
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Audit Certificate', style: TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 424,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF7CD57).withOpacity(0.3)),
                      gradient: const RadialGradient(
                        center: Alignment(0.5, 0.5), radius: 0.5,
                        colors: [Color(0xFF3D3214), Color(0xFF1A1710)],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: InteractiveViewer(
                        maxScale: 3,
                        minScale: 0.5,
                        child: _imageBytes != null
                            ? Transform.scale(
                                scale: _scale,
                                child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                              )
                            : const Center(child: CircularProgressIndicator(color: Color(0xFFF7CD57))),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Zoom controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF392D17),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFF7CD57)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _scale = (_scale + 0.15).clamp(0.5, 2.5)),
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFC9C9C9)),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _scale = (_scale - 0.15).clamp(0.5, 2.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: GestureDetector(
                  onTap: _downloadPdf,
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      gradient: LinearGradient(colors: [Color(0xFFFDD45B), Color(0xFFDE9C0A)]),
                    ),
                    child: Center(
                      child: _downloading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Download Audit Certificate',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
