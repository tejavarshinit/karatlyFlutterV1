import 'package:flutter/material.dart';

class SipScreen extends StatelessWidget {
  final int step;
  const SipScreen({super.key, this.step = 1});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      appBar: AppBar(title: Text('Gold SIP - Step $step')),
      body: Center(
        child: Text('Gold SIP Step $step', style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
