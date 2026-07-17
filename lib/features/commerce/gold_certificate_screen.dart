import 'package:flutter/material.dart';
import '../certificate/gold_certificate_screen.dart' as cert;

class GoldCertificateScreen extends StatefulWidget {
  const GoldCertificateScreen({super.key});

  @override
  State<GoldCertificateScreen> createState() => _GoldCertificateScreenWrapperState();
}

class _GoldCertificateScreenWrapperState extends State<GoldCertificateScreen> {
  @override
  Widget build(BuildContext context) {
    return const cert.GoldCertificateScreen();
  }
}
