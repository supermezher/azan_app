import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HijriCalendarScreen extends StatelessWidget {
  const HijriCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');
    HijriCalendar today = HijriCalendar.now();
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(title: const Text('التقويم الهجري والمناسبات', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1F2937), iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('التاريخ الهجري الحالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                '${today.hDay} ${today.longMonthName} ${today.hYear} هـ',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}