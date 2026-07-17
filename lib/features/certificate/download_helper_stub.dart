import 'dart:io';
import 'package:share_plus/share_plus.dart';

Future<void> downloadPdf(List<int> bytes, String fileName) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: fileName);
}
