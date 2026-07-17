import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final conversions = [
    ('assets/images/splash_jar.png', 400),
    ('assets/images/splash2_hero.png', 400),
    ('assets/images/splash2_bg.png', 400),
    ('assets/images/splash_logo.png', 120),
    ('assets/images/certificate/signature.png', 200),
    ('assets/images/certificate/stamp.png', 200),
    ('assets/images/goldcoin.png', 200),
    ('assets/images/silvercoin.png', 200),
    ('assets/images/certificate/audit_certificate.jpg', 800),
  ];
  for (final entry in conversions) {
    final path = entry.$1;
    final maxDim = entry.$2;
    final file = File(path);
    if (!file.existsSync()) {
      print('Not found: $path');
      continue;
    }
    final original = img.decodeImage(file.readAsBytesSync());
    if (original == null) {
      print('Failed to decode: $path');
      continue;
    }
    final oldLen = file.lengthSync();
    img.Image resized = original;
    if (original.width > maxDim || original.height > maxDim) {
      final ratio = maxDim / (original.width > original.height ? original.width : original.height);
      final w = (original.width * ratio).round();
      final h = (original.height * ratio).round();
      resized = img.copyResize(original, width: w, height: h);
    }
    final isJpg = path.endsWith('.jpg') || path.endsWith('.jpeg');
    final bytes = isJpg ? img.encodeJpg(resized, quality: 80) : img.encodePng(resized);
    file.writeAsBytesSync(bytes);
    final newLen = file.lengthSync();
    final oldKB = oldLen ~/ 1024;
    final newKB = newLen ~/ 1024;
    final saved = oldKB > 0 ? ((1 - newKB / oldKB) * 100).toStringAsFixed(0) : '0';
    print('$path: ${oldKB}KB -> ${newKB}KB ($saved% saved)');
  }
}
