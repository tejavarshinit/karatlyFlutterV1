import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateAuditCertificatePdf() async {
  final imageData = await rootBundle.load('assets/images/certificate/audit_certificate.jpg');
  final bytes = imageData.buffer.asUint8List();

  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        final pageWidth = PdfPageFormat.a4.width;
        final pageHeight = PdfPageFormat.a4.height;
        final img = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain);
        return pw.Center(child: pw.SizedBox(
          width: pageWidth,
          height: pageHeight,
          child: img,
        ));
      },
    ),
  );

  return doc.save();
}
