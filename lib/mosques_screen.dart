import 'package:flutter/material.dart';

class MosquesScreen extends StatelessWidget {
  final double lat;
  final double lng;
  const MosquesScreen({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(title: const Text('المساجد القريبة', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1F2937), iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mosque, size: 80, color: Colors.tealAccent),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🕌 جاري البحث عن المساجد حول موقعك...'), backgroundColor: Colors.teal));
              },
              icon: const Icon(Icons.map),
              label: const Text('عرض المساجد حول موقعي'),
            ),
          ],
        ),
      ),
    );
  }
}