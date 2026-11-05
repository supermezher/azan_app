import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class QiblaScreen extends StatefulWidget {
  final double qiblaDirection;

  const QiblaScreen({super.key, required this.qiblaDirection});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _heading;
  bool _hasCompass = true;

  @override
  void initState() {
    super.initState();
    // الاستماع لحساس البوصلة في الهاتف لتحديد اتجاه وجهة الهاتف الحقيقية
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    }, onError: (e) {
      setState(() {
        _hasCompass = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // حساب زاوية دوران المؤشر بناءً على اتجاه الهاتف وزاوية القبلة المحسوبة
    double qiblaAngle = widget.qiblaDirection;
    double compassHeading = _heading ?? 0;
    
    // حساب التوجيه النسبي للسهم
    double needleAngle = (qiblaAngle - compassHeading) * (math.pi / 180);

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('اتجاه القبلة', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.tealAccent),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'زاوية القبلة بالنسبة للشمال: ${qiblaAngle.toStringAsFixed(1)}°',
                style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // بوصلة بصرية دائرية تفاعلية
              _hasCompass
                  ? SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // إطار البوصلة الخارجي
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.teal.withOpacity(0.5), width: 4),
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          // أيقونة الكعبة أو مؤشر الاتجاه يدور حسب اتجاه الهاتف والقبلة
                          Transform.rotate(
                            angle: needleAngle,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.navigation, color: Colors.tealAccent, size: 80),
                                SizedBox(height: 120),
                              ],
                            ),
                          ),
                          // مركز البوصلة
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.tealAccent,
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        SizedBox(height: 16),
                        Text('حساس البوصلة غير متوفر في هذا الجهاز أو المحاكي.',
                            style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      ],
                    ),
              
              const SizedBox(height: 40),
              const Text(
                'قم بتحريك هاتفك في شكل رقم 8 لمعايرة البوصلة وضمان دقة الاتجاه نحو الكعبة المشرفة.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}