import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'invoice_data_service.dart';
import 'invoice_pdf_builder.dart';
import '../certificate/download_helper.dart';

class InvoiceScreen extends StatefulWidget {
  final String transactionId;
  final String type;

  const InvoiceScreen({
    super.key,
    required this.transactionId,
    required this.type,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  InvoiceData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndDownload();
  }

  Future<void> _loadAndDownload() async {
    setState(() { _loading = true; _error = null; });
    final r = await fetchInvoiceData(
      transactionId: widget.transactionId,
      type: widget.type,
    );
    if (!mounted) return;
    if (r['ok'] == true) {
      final data = r['data'] as InvoiceData;
      setState(() { _data = data; _loading = false; });
      // Auto-download like React (no preview)
      try {
        final bytes = await generateInvoicePdf(data, widget.type);
        final fileName = 'Invoice-${data.transactionId}.pdf';
        await downloadPdf(bytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice downloaded successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _error = 'Download failed: $e');
        }
      }
    } else {
      setState(() { _error = r['message']?.toString() ?? 'Failed to load invoice'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating invoice...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadAndDownload, child: const Text('Retry')),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
