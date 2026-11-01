import 'package:flutter/material.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final TextEditingController _moneyController = TextEditingController();
  double _zakatResult = 0.0;

  void _calculateZakat() {
    double money = double.tryParse(_moneyController.text) ?? 0.0;
    setState(() {
      _zakatResult = money * 0.025;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('حاسبة الزكاة الذكية 💰', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('احسب زكاة مالك بدقة (بنسبة 2.5% للعام الهجري):', style: TextStyle(color: Colors.tealAccent, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              controller: _moneyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'أدخل إجمالي المبلغ النقدي...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _calculateZakat,
              child: const Text('احسب الزكاة المستحقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Text('إجمالي الزكاة الواجب إخراجها:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '$_zakatResult ريال / عملة محلية',
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}