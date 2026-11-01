import 'package:flutter/material.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(title: const Text('أذكار الصباح والمساء', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1F2937), iconTheme: const IconThemeData(color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Color(0xFF1F2937),
            child: ListTile(
              title: Text('أصبحنا وأصبح الملك لله والحمد لله...', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}