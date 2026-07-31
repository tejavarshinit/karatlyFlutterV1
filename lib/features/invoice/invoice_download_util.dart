import 'package:flutter/material.dart';
import 'invoice_data_service.dart';
import 'invoice_pdf_builder.dart';
import '../certificate/download_helper.dart';

/// Downloads an invoice directly without navigating to a preview screen.
/// Returns true on success, false on failure.
Future<bool> downloadInvoice({
  required BuildContext context,
  required String transactionId,
  required String type,
  bool showSnackBar = true,
}) async {
  try {
    final r = await fetchInvoiceData(
      transactionId: transactionId,
      type: type,
    );
    if (r['ok'] != true) {
      if (showSnackBar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message']?.toString() ?? 'Failed to load invoice')),
        );
      }
      return false;
    }
    final data = r['data'] as InvoiceData;
    final bytes = await generateInvoicePdf(data, type);
    final fileName = 'Invoice-${data.transactionId}.pdf';
    await downloadPdf(bytes, fileName);
    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice downloaded successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return true;
  } catch (e) {
    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
    return false;
  }
}
