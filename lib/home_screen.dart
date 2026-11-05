import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:adhan/adhan.dart';

import 'fasting_tracker_screen.dart';
import 'zakat_screen.dart';
import 'quran_screen.dart';
import 'qibla_screen.dart';
import 'mosques_screen.dart';
import 'tasbih_screen.dart';
import 'adhkar_screen.dart';
import 'hisn_screen.dart';
import 'hijri_calendar_screen.dart';
import 'city_search_screen.dart';
import 'prayer_settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _qiblaDirection;
  
  double _currentLat = 21.3891; // مكة المكرمة افتراضياً
  double _currentLng = 39.8579;
  
  String _cityName = 'مكة المكرمة';
  bool _isLoading = true;
  String? _errorMessage;
  
  int _calculationMethod = 3;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  String _countdownText = '';
  String _nextPrayerName = '';
  bool _isPlayingAzan = false;

  String _gregorianDateStr = '';
  String _hijriDateStr = '';

  String _selectedMuadhin = 'أذان الحرم المكي';
  bool _autoSilentEnabled = false;
  int _fajrAdjustment = 0;
  int _dhuhrAdjustment = 0;
  int _asrAdjustment = 0;
  int _maghribAdjustment = 0;
  int _ishaAdjustment = 0;

  DateTime? _fajrTime;
  DateTime? _sunriseTime;
  DateTime? _dhuhrTime;
  DateTime? _asrTime;
  DateTime? _maghribTime;
  DateTime? _ishaTime;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFetch();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAzan = state.playing;
        });
      }
    });
  }

  Future<void> _loadSettingsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMuadhin = prefs.getString('selected_muadhin') ?? 'أذان الحرم المكي';
      _autoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
      _calculationMethod = prefs.getInt('calculation_method') ?? 3;
      
      _fajrAdjustment = prefs.getInt('fajr_adj') ?? 0;
      _dhuhrAdjustment = prefs.getInt('dhuhr_adj') ?? 0;
      _asrAdjustment = prefs.getInt('asr_adj') ?? 0;
      _maghribAdjustment = prefs.getInt('maghrib_adj') ?? 0;
      _ishaAdjustment = prefs.getInt('isha_adj') ?? 0;

      // استرجاع الموقع المحفوظ إن وُجد لضمان ثباته
      if (prefs.containsKey('saved_lat') && prefs.containsKey('saved_lng')) {
        _currentLat = prefs.getDouble('saved_lat')!;
        _currentLng = prefs.getDouble('saved_lng')!;
        _cityName = prefs.getString('saved_city_name') ?? 'موقعي المحفوظ';
      }
    });

    _loadDates();

    // إذا كان الموقع محفوظاً مسبقاً، نستخدمه مباشرة، وإلا نبحث عبر GPS
    if (prefs.containsKey('saved_lat')) {
      _calculateQiblaDirection();
      await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
    } else {
      await _checkLocationAndFetchTimes();
    }
  }

  void _loadDates() {
    final now = DateTime.now();
    _gregorianDateStr = DateFormat('yyyy/MM/dd', 'ar').format(now);
    
    HijriCalendar.setLocal('ar');
    HijriCalendar todayHijri = HijriCalendar.now();
    _hijriDateStr = '${todayHijri.hDay} ${todayHijri.longMonthName} ${todayHijri.hYear} هـ';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_fajrTime == null) return;
    
    final now = DateTime.now();
    
    List prayers = [
      {'name': 'الفجر', 'time': _fajrTime},
      {'name': 'الشروق', 'time': _sunriseTime},
      {'name': 'الظهر', 'time': _dhuhrTime},
      {'name': 'العصر', 'time': _asrTime},
      {'name': 'المغرب', 'time': _maghribTime},
      {'name': 'العشاء', 'time': _ishaTime},
    ];

    Map? nextPrayer;
    for (var p in prayers) {
      DateTime pTime = p['time'];
      if (now.isBefore(pTime)) {
        nextPrayer = p;
        break;
      }
    }

    DateTime targetTime;
    if (nextPrayer == null) {
      _nextPrayerName = 'الفجر (غداً)';
      targetTime = _fajrTime!.add(const Duration(days: 1));
    } else {
      _nextPrayerName = nextPrayer['name'];
      targetTime = nextPrayer['time'];
    }

    final difference = targetTime.difference(now);
    if (difference.inSeconds <= 0) {
      if (mounted) setState(() => _countdownText = 'حان الآن وقت الصلاة');
      return;
    }

    int hours = difference.inHours;
    int minutes = difference.inMinutes % 60;
    int seconds = difference.inSeconds % 60;

    if (mounted) {
      setState(() {
        _countdownText = '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _toggleAzan() async {
    try {
      if (_isPlayingAzan) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.setAsset('assets/audio/azan.mp3');
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("خطأ في الصوت: $e");
    }
  }

  // حساب اتجاه القبلة الحقيقي بناءً على الإحداثيات
  void _calculateQiblaDirection() {
    final coordinates = Coordinates(_currentLat, _currentLng);
    setState(() {
      _qiblaDirection = Qibla(coordinates).direction;
    });
  }

  Future<void> _checkLocationAndFetchTimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _calculateQiblaDirection();
        await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _calculateQiblaDirection();
          await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _calculateQiblaDirection();
        await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // حفظ الموقع المكتشف تلقائياً عبر GPS
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('saved_lat', _currentLat);
      await prefs.setDouble('saved_lng', _currentLng);
      await prefs.setString('saved_city_name', _cityName);

      _calculateQiblaDirection();

      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$_currentLat&lon=$_currentLng&accept-language=ar');
        final response = await http.get(url, headers: {'User-Agent': 'IslamicPrayerApp/1.0'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'];
          if (mounted) {
            setState(() {
              _cityName = address['city'] ?? address['town'] ?? address['village'] ?? 'موقعي الحالي';
            });
            await prefs.setString('saved_city_name', _cityName);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _cityName = 'موقعي الحالي (GPS)');
        }
      }

      await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
    } catch (e) {
      _calculateQiblaDirection();
      await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
    }
  }

  Future<void> _fetchPrayerTimesFromApi(double lat, double lng) async {
    try {
      final now = DateTime.now();
      final String dateStr = "${now.day}-${now.month}-${now.year}";

      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&method=$_calculationMethod'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        if (mounted) {
          setState(() {
            _fajrTime = _parseTimeString(timings['Fajr']).add(Duration(minutes: _fajrAdjustment));
            _sunriseTime = _parseTimeString(timings['Sunrise']);
            _dhuhrTime = _parseTimeString(timings['Dhuhr']).add(Duration(minutes: _dhuhrAdjustment));
            _asrTime = _parseTimeString(timings['Asr']).add(Duration(minutes: _asrAdjustment));
            _maghribTime = _parseTimeString(timings['Maghrib']).add(Duration(minutes: _maghribAdjustment));
            _ishaTime = _parseTimeString(timings['Isha']).add(Duration(minutes: _ishaAdjustment));
            
            _isLoading = false;
            _errorMessage = null;
          });
        }
        _startCountdown();
      } else {
        _calculatePrayerTimesLocally(lat, lng);
      }
    } catch (e) {
      debugPrint("خطأ في الاتصال بالـ API، جاري التفعيل البديل المحلي: $e");
      _calculatePrayerTimesLocally(lat, lng);
    }
  }

  // دالة الحساب المحلي البديل المتوافقة مع الإصدار 2.0.0+ من حزمة adhan
  void _calculatePrayerTimesLocally(double lat, double lng) {
    try {
      final coordinates = Coordinates(lat, lng);
      final date = DateComponents.from(DateTime.now());
      
      CalculationParameters params;
      switch (_calculationMethod) {
        case 1:
          params = CalculationMethod.karachi.getParameters();
          break;
        case 2:
          params = CalculationMethod.north_america.getParameters();
          break;
        case 3:
          params = CalculationMethod.muslim_world_league.getParameters();
          break;
        case 4:
          params = CalculationMethod.umm_al_qura.getParameters();
          break;
        case 5:
          params = CalculationMethod.egyptian.getParameters();
          break;
        default:
          params = CalculationMethod.muslim_world_league.getParameters();
          break;
      }

      final prayerTimes = PrayerTimes(coordinates, date, params);

      if (mounted) {
        setState(() {
          _fajrTime = prayerTimes.fajr.add(Duration(minutes: _fajrAdjustment));
          _sunriseTime = prayerTimes.sunrise;
          _dhuhrTime = prayerTimes.dhuhr.add(Duration(minutes: _dhuhrAdjustment));
          _asrTime = prayerTimes.asr.add(Duration(minutes: _asrAdjustment));
          _maghribTime = prayerTimes.maghrib.add(Duration(minutes: _maghribAdjustment));
          _ishaTime = prayerTimes.isha.add(Duration(minutes: _ishaAdjustment));
          
          _isLoading = false;
          _errorMessage = null;
        });
      }
      _startCountdown();
    } catch (e) {
      debugPrint("خطأ في الحساب المحلي: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر جلب أوقات الصلاة عبر الإنترنت أو الحساب المحلي.';
        });
      }
    }
  }

  DateTime _parseTimeString(String timeStr) {
    try {
      final cleanTime = timeStr.split(' ')[0];
      final parts = cleanTime.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _openCitySearchScreen() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CitySearchScreen()));
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _cityName = result['name'];
        _currentLat = result['lat'];
        _currentLng = result['lng'];
      });

      // حفظ الموقع الجديد فوراً في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('saved_lat', _currentLat);
      await prefs.setDouble('saved_lng', _currentLng);
      await prefs.setString('saved_city_name', _cityName);

      _calculateQiblaDirection();
      await _fetchPrayerTimesFromApi(_currentLat, _currentLng);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => PrayerSettingsDialog(
        currentLat: _currentLat,
        currentLng: _currentLng,
        onSettingsChanged: () {
          _loadSettingsAndFetch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: InkWell(
          onTap: _openCitySearchScreen,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_cityName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  const Icon(Icons.location_on, color: Colors.tealAccent, size: 18),
                ],
              ),
              Text('$_hijriDateStr | $_gregorianDateStr (اضغط لتغيير المدينة)', style: const TextStyle(color: Colors.tealAccent, fontSize: 10)),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1F2937),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.tealAccent),
          onPressed: _showSettingsDialog,
          tooltip: 'الإعدادات',
        ),
        actions: [
          IconButton(
            icon: Icon(_isPlayingAzan ? Icons.stop_circle : Icons.volume_up, color: _isPlayingAzan ? Colors.redAccent : Colors.tealAccent),
            onPressed: _toggleAzan,
            tooltip: 'الأذان',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: _checkLocationAndFetchTimes,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildNextPrayerCard(),
                    const SizedBox(height: 16),
                    const Text('🌟 أقسام التطبيق الشاملة:', style: TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildFeatureCard('القرآن', Icons.menu_book, const QuranListScreen()),
                        _buildFeatureCard('القبلة', Icons.explore, QiblaScreen(qiblaDirection: _qiblaDirection ?? 0)),
                        _buildFeatureCard('المساجد', Icons.mosque, MosquesScreen(lat: _currentLat, lng: _currentLng)),
                        _buildFeatureCard('المسبحة', Icons.fingerprint, const TasbihScreen()),
                        _buildFeatureCard('الأذكار', Icons.auto_stories, const AdhkarScreen()),
                        _buildFeatureCard('حصن المسلم', Icons.menu_book_rounded, const HisnScreen()),
                        _buildFeatureCard('حاسبة الزكاة', Icons.calculate, ZakatCalculatorScreen()),
                        _buildFeatureCard('التقويم', Icons.calendar_month, const HijriCalendarScreen()),
                        _buildFeatureCard('متتبع الصيام', Icons.event_available, FastingTrackerScreen()),
                        _buildFeatureCard('المدينة والـ GPS', Icons.location_city, const CitySearchScreen(isInternalRoute: true)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('🕌 أوقات الصلوات اليومية:', style: TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _prayerTile('الفجر', _fajrTime),
                    _prayerTile('الشروق', _sunriseTime),
                    _prayerTile('الظهر', _dhuhrTime),
                    _prayerTile('العصر', _asrTime),
                    _prayerTile('المغرب', _maghribTime),
                    _prayerTile('العشاء', _ishaTime),
                  ],
                ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, Widget targetScreen) {
    return InkWell(
      onTap: () {
        if (title == 'القبلة' && _qiblaDirection != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => QiblaScreen(qiblaDirection: _qiblaDirection!)));
        } else if (title == 'المدينة والـ GPS') {
          _openCitySearchScreen();
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
        }
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.withOpacity(0.4))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.tealAccent, size: 24),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _prayerTile(String title, DateTime? time) {
    final formattedTime = time != null ? DateFormat('jm', 'ar').format(time) : '--:--';
    
    return Card(
      color: const Color(0xFF1F2937),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: Text(formattedTime, style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('الصلاة القادمة (المؤذن: $_selectedMuadhin)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_nextPrayerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_countdownText, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        ],
      ),
    );
  }
}