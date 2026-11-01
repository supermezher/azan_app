import 'package:flutter/material.dart';

class QiblaScreen extends StatelessWidget {
  final double qiblaDirection;
  const QiblaScreen({super.key, required this.qiblaDirection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(title: const Text('اتجاه القبلة', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1F2937), iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('زاوية القبلة: ${qiblaDirection.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.tealAccent, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Icon(Icons.explore, size: 150, color: Colors.tealAccent),
          ],
        ),
      ),
    );
  }
}