import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class ArQiblaScreen extends StatefulWidget {
  final double qiblaDirection; // زاوية القبلة المحسوبة مسبقاً بالنسبة للشمال
  const ArQiblaScreen({super.key, required this.qiblaDirection});

  @override
  State<ArQiblaScreen> createState() => _ArQiblaScreenState();
}

class _ArQiblaScreenState extends State<ArQiblaScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  double? _deviceHeading;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initCompass();
  }

  // تهيئة كاميرا الهاتف
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print("خطأ في تشغيل الكاميرا: $e");
    }
  }

  // تتبع حركة البوصلة واتجاه الهاتف
  void _initCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _deviceHeading = event.heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // عرض شاشة تحميل أثناء تهيئة الكاميرا
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF111827),
        appBar: AppBar(
          title: const Text('القبلة بالواقع المعزز (AR)', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1F2937),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    // حساب الزاوية النسبية بين اتجاه الهاتف الحالي وزاوية القبلة الحقيقية
    double heading = _deviceHeading ?? 0;
    double targetAngle = widget.qiblaDirection - heading;
    double angleInRadians = targetAngle * (math.pi / 180);

    return Scaffold(
      body: Stack(
        children: [
          // 1. معاينة الكاميرا في الخلفية بملء الشاشة
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // 2. طبقة تعتيم خفيفة لإبراز عناصر الواقع المعزز فوق الكاميرا
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),

          // 3. شريط علوي شفاف للرجوع
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              title: const Text('القبلة بالواقع المعزز (AR)', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
          ),

          // 4. مؤشر القبلة العائم (العنصر البصري للواقع المعزز)
          Center(
            child: Transform.rotate(
              angle: angleInRadians,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.7),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Color(0xFF111827),
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.tealAccent, width: 1.5),
                    ),
                    child: const Text(
                      'الكعبة المشرفة 🕋',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. إرشادات سفلية للمستخدم
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'وجه الكاميرا نحو الأفق وحرك هاتفك يميناً ويساراً حتى يستقر السهم في المنتصف تماماً.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}