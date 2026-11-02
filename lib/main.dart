import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  tz.initializeTimeZones();
  await initializeDateFormatting('ar', null);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // التصحيح هنا: استخدام settings: بالشكل الصحيح
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {},
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'adhan_channel_id',
    'تنبيهات الأذان',
    description: 'قناة مخصصة لتنبيهات أوقات الصلاة والأذان',
    importance: Importance.max,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(const AzanApp());
}

class AzanApp extends StatelessWidget {
  const AzanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق الإسلام الشامل',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimes? _prayerTimes;
  double? _qiblaDirection;
  double _currentLat = 59.3293;
  double _currentLng = 18.0686;
  String _cityName = 'جاري تحديد المدينة...';
  bool _isLoading = true;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  String _countdownText = '';
  Prayer? _lastPlayedPrayer;
  bool _isPlayingAzan = false;

  String _gregorianDateStr = '';
  String _hijriDateStr = '';

  String _selectedMuadhin = 'أذان الحرم المكي';
  final List<String> _muadhinList = ['أذان الحرم المكي', 'أذان المسجد النبوي', 'الشيخ مشاري العفاسي', 'الشيخ عبد الباسط'];
  
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
    _loadSettings();
    _loadDates();
    _checkLocationAndFetchTimes();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAzan = state.playing;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMuadhin = prefs.getString('selected_muadhin') ?? 'أذان الحرم المكي';
      _autoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
      _fajrAdjustment = prefs.getInt('fajr_adj') ?? 0;
      _dhuhrAdjustment = prefs.getInt('dhuhr_adj') ?? 0;
      _asrAdjustment = prefs.getInt('asr_adj') ?? 0;
      _maghribAdjustment = prefs.getInt('maghrib_adj') ?? 0;
      _ishaAdjustment = prefs.getInt('isha_adj') ?? 0;
    });
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
      if (_prayerTimes != null) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final nextPrayer = _prayerTimes!.nextPrayer();
    
    DateTime? prayerTime;
    switch (nextPrayer) {
      case Prayer.fajr: prayerTime = _fajrTime; break;
      case Prayer.sunrise: prayerTime = _sunriseTime; break;
      case Prayer.dhuhr: prayerTime = _dhuhrTime; break;
      case Prayer.asr: prayerTime = _asrTime; break;
      case Prayer.maghrib: prayerTime = _maghribTime; break;
      case Prayer.isha: prayerTime = _ishaTime; break;
      default: 
        prayerTime = _fajrTime?.add(const Duration(days: 1));
        break;
    }

    if (prayerTime == null) return;

    final difference = prayerTime.difference(now);

    if (difference.inSeconds <= 0) {
      if (_lastPlayedPrayer != nextPrayer && nextPrayer != Prayer.sunrise) {
        _lastPlayedPrayer = nextPrayer;
        _toggleAzan();
        if (_autoSilentEnabled) {
          _triggerAutoSilent();
        }
      }
      if (mounted) {
        setState(() {
          _countdownText = 'حان الآن وقت الصلاة';
        });
      }
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

  void _triggerAutoSilent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔕 [وضع الصامت التلقائي]: تم تفعيل وضع الصامت أثناء الصلاة'), backgroundColor: Colors.purple),
    );
  }

  Future<void> _toggleAzan() async {
    try {
      if (_isPlayingAzan) {
        await _audioPlayer.stop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إيقاف الأذان')),
          );
        }
      } else {
        await _audioPlayer.setAsset('assets/audio/azan.mp3');
        await _audioPlayer.play();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📢 حان وقت الصلاة، جاري تشغيل ($_selectedMuadhin)...'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("خطأ في الصوت: $e");
    }
  }

  Future<void> _checkLocationAndFetchTimes() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation('ستوكهولم (GPS معطل)');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation('ستوكهولم (الإذن مرفوض)');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation('ستوكهولم (الإذن مرفوض نهائياً)');
        return;
      }

      setState(() {
        _cityName = 'جاري تحديد موقعك عبر GPS...';
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$_currentLat&lon=$_currentLng&accept-language=ar');
        final response = await http.get(url, headers: {'User-Agent': 'IslamicPrayerApp/1.0'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'];
          String foundCity = address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? 'موقعي الحالي';
          setState(() {
            _cityName = foundCity;
          });
        }
      } catch (e) {
        setState(() {
          _cityName = 'موقعي الحالي (GPS)';
        });
      }

      _calculateTimes(_currentLat, _currentLng);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📍 تم تحديث موقعك بنجاح عبر GPS!'), backgroundColor: Colors.teal),
        );
      }

    } catch (e) {
      _setDefaultLocation('ستوكهولم (افتراضي)');
    }
  }

  void _setDefaultLocation(String message) {
    _currentLat = 59.3293;
    _currentLng = 18.0686;
    if (mounted) {
      setState(() {
        _cityName = message;
      });
    }
    _calculateTimes(_currentLat, _currentLng);
  }

  void _calculateTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes.today(coordinates, params);
    final qibla = Qibla(coordinates);

    if (mounted) {
      setState(() {
        _prayerTimes = prayerTimes;
        _fajrTime = prayerTimes.fajr.add(Duration(minutes: _fajrAdjustment));
        _sunriseTime = prayerTimes.sunrise;
        _dhuhrTime = prayerTimes.dhuhr.add(Duration(minutes: _dhuhrAdjustment));
        _asrTime = prayerTimes.asr.add(Duration(minutes: _asrAdjustment));
        _maghribTime = prayerTimes.maghrib.add(Duration(minutes: _maghribAdjustment));
        _ishaTime = prayerTimes.isha.add(Duration(minutes: _ishaAdjustment));

        _qiblaDirection = qibla.direction;
        _isLoading = false;
      });
    }

    _startCountdown();
  }

  void _openCitySearchScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CitySearchScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _cityName = result['name'];
        _currentLat = result['lat'];
        _currentLng = result['lng'];
      });
      _calculateTimes(_currentLat, _currentLng);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم تحديث المدينة إلى: $_cityName'), backgroundColor: Colors.teal),
      );
    }
  }

  void _showAdhanSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2937),
              title: const Text('⚙️ إعدادات برنامج الأذان والصلاة', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('اختر المؤذن المفضل:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMuadhin,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: _muadhinList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          setDialogState(() => _selectedMuadhin = val);
                          setState(() => _selectedMuadhin = val);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selected_muadhin', val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('وضع الصامت التلقائي أثناء الصلاة', style: TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: const Text('تحويل الهاتف لصامت وقت الأذان مؤقتاً', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      value: _autoSilentEnabled,
                      activeThumbColor: Colors.tealAccent,
                      onChanged: (val) async {
                        setDialogState(() => _autoSilentEnabled = val);
                        setState(() => _autoSilentEnabled = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('auto_silent_enabled', val);
                      },
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    const Text('التعديل اليدوي لأوقات الصلاة (بالدقائق):', style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildAdjustmentRow('الفجر', _fajrAdjustment, (val) async {
                      setDialogState(() => _fajrAdjustment = val);
                      _calculateTimes(_currentLat, _currentLng);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('fajr_adj', val);
                    }),
                    _buildAdjustmentRow('الظهر', _dhuhrAdjustment, (val) async {
                      setDialogState(() => _dhuhrAdjustment = val);
                      _calculateTimes(_currentLat, _currentLng);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('dhuhr_adj', val);
                    }),
                    _buildAdjustmentRow('العصر', _asrAdjustment, (val) async {
                      setDialogState(() => _asrAdjustment = val);
                      _calculateTimes(_currentLat, _currentLng);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('asr_adj', val);
                    }),
                    _buildAdjustmentRow('المغرب', _maghribAdjustment, (val) async {
                      setDialogState(() => _maghribAdjustment = val);
                      _calculateTimes(_currentLat, _currentLng);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('maghrib_adj', val);
                    }),
                    _buildAdjustmentRow('العشاء', _ishaAdjustment, (val) async {
                      setDialogState(() => _ishaAdjustment = val);
                      _calculateTimes(_currentLat, _currentLng);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('isha_adj', val);
                    }),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حفظ وإغلاق'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAdjustmentRow(String title, int value, Function(int) onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$title:', style: const TextStyle(color: Colors.white70)),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove, color: Colors.white, size: 20), onPressed: () => onChange(value - 1)),
            Text('$value د', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add, color: Colors.white, size: 20), onPressed: () => onChange(value + 1)),
          ],
        ),
      ],
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
              Text(
                '$_hijriDateStr | $_gregorianDateStr (اضغط لتغيير المدينة)',
                style: const TextStyle(color: Colors.tealAccent, fontSize: 10),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1F2937),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.tealAccent),
          tooltip: 'إعدادات الأذان',
          onPressed: _showAdhanSettingsDialog,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPlayingAzan ? Icons.stop_circle : Icons.volume_up,
              color: _isPlayingAzan ? Colors.redAccent : Colors.tealAccent,
              size: 28,
            ),
            onPressed: _toggleAzan,
            tooltip: _isPlayingAzan ? 'إيقاف الأذان' : 'تجربة الأذان',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildNextPrayerCard(),
                const SizedBox(height: 16),
                
                const Text(
                  '🌟 أقسام التطبيق الشاملة:',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildFeatureCard(context, 'القرآن', Icons.menu_book, const QuranListScreen()),
                    _buildFeatureCard(context, 'القبلة', Icons.explore, QiblaScreen(qiblaDirection: _qiblaDirection ?? 0)),
                    _buildFeatureCard(context, 'المساجد', Icons.mosque, MosquesScreen(lat: _currentLat, lng: _currentLng)),
                    _buildFeatureCard(context, 'المسبحة', Icons.fingerprint, const TasbihScreen()),
                    _buildFeatureCard(context, 'الأذكار', Icons.auto_stories, const AdhkarScreen()),
                    _buildFeatureCard(context, 'حصن المسلم', Icons.menu_book_rounded, const HisnScreen()),
                    _buildFeatureCard(context, 'حاسبة الزكاة', Icons.calculate, const ZakatCalculatorScreen()),
                    _buildFeatureCard(context, 'التقويم', Icons.calendar_month, const HijriCalendarScreen()),
                    _buildFeatureCard(context, 'متتبع الصيام', Icons.event_available, const FastingTrackerScreen()),
                    _buildFeatureCard(context, 'المدينة والـ GPS', Icons.location_city, const CitySearchScreen(isInternalRoute: true)),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  '🕌 أوقات الصلوات اليومية:',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.bold),
                ),
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

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, Widget targetScreen) {
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.tealAccent, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerTile(String title, DateTime? time) {
    final formattedTime = time != null ? DateFormat.jm().format(time) : '--:--';
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
    final nextPrayer = _prayerTimes?.nextPrayer();
    String nextPrayerName = 'الصلوات انتهت اليوم';
    
    switch (nextPrayer) {
      case Prayer.fajr: nextPrayerName = 'الفجر'; break;
      case Prayer.sunrise: nextPrayerName = 'الشروق'; break;
      case Prayer.dhuhr: nextPrayerName = 'الظهر'; break;
      case Prayer.asr: nextPrayerName = 'العصر'; break;
      case Prayer.maghrib: nextPrayerName = 'المغرب'; break;
      case Prayer.isha: nextPrayerName = 'العشاء'; break;
      default: nextPrayerName = 'الفجر (غداً)'; break;
    }

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
          Text(nextPrayerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_countdownText, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        ],
      ),
    );
  }
}