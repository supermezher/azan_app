import 'package:flutter/material.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(title: const Text('المسبحة الإلكترونية', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1F2937), iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _counter++),
              child: Container(
                width: 200, height: 200,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.teal),
                child: Center(child: Text('$_counter', style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => setState(() => _counter = 0),
              child: const Text('تصفير العداد'),
            ),
          ],
        ),
      ),
    );
  }
}