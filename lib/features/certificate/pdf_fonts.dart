import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFonts {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _load() async {
    if (_regular != null) return;
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }

  static Future<pw.Font> regular() async {
    await _load();
    return _regular!;
  }

  static Future<pw.Font> bold() async {
    await _load();
    return _bold!;
  }

  static Future<pw.TextStyle> style({
    double fontSize = 10,
    bool bold = false,
    int? color,
    double? letterSpacing,
    double? lineSpacing,
  }) async {
    final font = bold ? await bold() : await regular();
    return pw.TextStyle(
      font: font,
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color != null ? PdfColor.fromInt(color) : PdfColors.black,
      letterSpacing: letterSpacing,
      lineSpacing: lineSpacing,
    );
  }
}
