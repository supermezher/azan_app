import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CitySearchScreen extends StatefulWidget {
  final bool isInternalRoute;
  const CitySearchScreen({super.key, this.isInternalRoute = false});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  Future<void> _searchCityGlobal(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&accept-language=ar');
      final response = await http.get(url, headers: {'User-Agent': 'IslamicPrayerApp/1.0'});

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final place = results[0];
          double lat = double.parse(place['lat']);
          double lng = double.parse(place['lon']);
          String fullName = place['display_name'].toString().split(',')[0];

          if (mounted) {
            Navigator.pop(context, {'name': fullName, 'lat': lat, 'lng': lng});
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ لم يتم العثور على هذا المكان. تأكد من صحة الاسم.'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ حدث خطأ في الاتصال بالإنترنت أثناء البحث.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocationGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ خدمات الموقع (GPS) غير مفعلة.'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      setState(() {
        _isSearching = true;
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lng = position.longitude;
      String cityName = 'موقعي الحالي';

      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ar');
        final response = await http.get(url, headers: {'User-Agent': 'IslamicPrayerApp/1.0'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'];
          cityName = address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? 'موقعي الحالي';
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context, {'name': cityName, 'lat': lat, 'lng': lng});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ تعذر تحديد الموقع عبر GPS.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('📍 تحديد المدينة والـ GPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.tealAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              '🌍 اختر طريقة تحديد موقعك:',
              style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSearching ? null : _getCurrentLocationGPS,
              icon: const Icon(Icons.my_location, size: 22),
              label: const Text('تحديد موقعي الحالي تلقائياً (GPS)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              '🔍 البحث اليدوي عن أي مدينة أو قرية:',
              style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'اكتب اسم أي مدينة أو قرية في العالم (بالعربية أو الإإنجليزية):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: الرباط، ستوكهولم، الدار البيضاء...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
              ),
              onSubmitted: (value) => _searchCityGlobal(value),
            ),
            const SizedBox(height: 16),
            _isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _searchCityGlobal(_searchController.text),
                    child: const Text('بحث في قاعدة بيانات العالم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}