import 'package:flutter/material.dart';

class HisnScreen extends StatelessWidget {
  const HisnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(title: const Text('حصن المسلم والأدعية', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1F2937), iconTheme: const IconThemeData(color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Color(0xFF1F2937),
            child: ListTile(
              title: Text('دعاء الكرب والهم', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
              subtitle: Text('لا إله إلا الله العظيم الحليم، لا إله إلا الله رب العرش العظيم...', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}