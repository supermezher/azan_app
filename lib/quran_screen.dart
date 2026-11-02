import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:async';
import 'quran_khatma_screen.dart';
import 'quran_analytics_screen.dart';
import 'quran_bookmarks_screen.dart';
import 'quran_settings_hub.dart';

class QuranListScreen extends StatefulWidget {
  const QuranListScreen({super.key});

  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}

class _QuranListScreenState extends State<QuranListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  
  int? _lastReadSurah;
  int? _lastReadVerse;
  String _lastReadSurahName = '';

  final List _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReadSurah = prefs.getInt('last_surah');
      _lastReadVerse = prefs.getInt('last_verse');
      
      // التعامل الآمن مع القيمة لمنع خطأ الـ Null
      Object? nameObj = prefs.get('last_surah_name');
      _lastReadSurahName = nameObj != null ? nameObj.toString() : '';
    });
  }

  String _removeTashkeel(String text) {
    final arabicTashkeel = RegExp(r'[\u0617-\u061A\u064B-\u0652\u0670]');
    return text.replaceAll(arabicTashkeel, '').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ى', 'ي');
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _searchResults.clear();

      if (_searchQuery.length >= 2) {
        String cleanQuery = _removeTashkeel(_searchQuery);
        for (int s = 1; s <= 114; s++) {
          int vCount = quran.getVerseCount(s);
          for (int v = 1; v <= vCount; v++) {
            String verseText = quran.getVerse(s, v);
            String cleanVerse = _removeTashkeel(verseText);
            if (cleanVerse.contains(cleanQuery)) {
              _searchResults.add({
                'surah': s,
                'surahName': quran.getSurahNameArabic(s),
                'verseNum': v,
                'text': verseText,
              });
              if (_searchResults.length > 50) break;
            }
          }
          if (_searchResults.length > 50) break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('المصحف الشريف 📖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks, color: Colors.amberAccent),
            tooltip: 'مركز العلامات والمفضلة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranBookmarksScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.tealAccent),
            tooltip: 'الإعدادات والتنبيهات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranSettingsHubScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.tealAccent),
            tooltip: 'خطة الختمة والورد اليومي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranKhatmaScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.tealAccent),
            tooltip: 'لوحة إحصاءات القراءة والختمات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranAnalyticsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: 'السور (114)'),
            Tab(text: 'الأجزاء (30)'),
            Tab(text: 'البحث في الآيات'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_lastReadSurah != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📌 فاصل القراءة الحالي:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        'سورة $_lastReadSurahName - الآية ($_lastReadVerse)',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.tealAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurahDetailScreen(
                            surahNumber: _lastReadSurah!,
                            surahName: _lastReadSurahName,
                            initialVerse: _lastReadVerse,
                          ),
                        ),
                      ).then((_) => _loadLastRead());
                    },
                    child: const Text('متابعة'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurahListTab(),
                _buildJuzIndexTab(),
                _buildVerseSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahListTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم السورة...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 114,
            itemBuilder: (context, index) {
              int surahNumber = index + 1;
              String surahName = quran.getSurahNameArabic(surahNumber);
              int versesCount = quran.getVerseCount(surahNumber);
              String place = quran.getPlaceOfRevelation(surahNumber) == 'Makkah' ? 'مكية' : 'مدنية';

              if (_searchQuery.isNotEmpty && !surahName.contains(_searchQuery)) {
                return const SizedBox.shrink();
              }

              return Card(
                color: const Color(0xFF1F2937),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade800,
                    child: Text('$surahNumber', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('سورة $surahName', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text('$place • عدد آياتها: $versesCount', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.tealAccent, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurahDetailScreen(surahNumber: surahNumber, surahName: surahName),
                      ),
                    ).then((_) => _loadLastRead());
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJuzIndexTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 30,
      itemBuilder: (context, index) {
        int juzNumber = index + 1;
        return Card(
          color: const Color(0xFF1F2937),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade800,
              child: Text('$juzNumber', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            ),
            title: Text('الجزء رقم ($juzNumber)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: const Text('اضغط للاستعراض والقراءة السريعة', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amberAccent, size: 14),
            onTap: () {
              int estimatedSurah = juzNumber == 1 ? 1 : (juzNumber * 3).clamp(1, 114);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(
                    surahNumber: estimatedSurah,
                    surahName: quran.getSurahNameArabic(estimatedSurah),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVerseSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'اكتب كلمة للبحث عنها (بدون تشكيل)...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.travel_explore, color: Colors.tealAccent),
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => _performSearch(val),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _searchQuery.length < 2
                ? const Center(child: Text('اكتب حرفين أو أكثر للبحث في القرآن الكريم...', style: TextStyle(color: Colors.white54)))
                : _searchResults.isEmpty
                    ? const Center(child: Text('لم يتم العثور على نتائج مطابقة', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index] as Map<String, dynamic>;
                          return Card(
                            color: const Color(0xFF1F2937),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                item['text'],
                                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                                textAlign: TextAlign.right,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'سورة ${item['surahName']} - الآية (${item['verseNum']})',
                                  style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SurahDetailScreen(
                                      surahNumber: item['surah'],
                                      surahName: item['surahName'],
                                      initialVerse: item['verseNum'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// شاشة قراءة السورة المتكاملة
// ----------------------------------------------------
class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialVerse;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialVerse,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  int _themeModeIndex = 0; 
  
  bool _isZenMode = false;
  bool _isMemorizationMode = false;
  double _fontSize = 22.0;
  late final AudioPlayer _audioPlayer;
  int? _playingVerse;
  bool _isPlayingFullSurah = false;
  final ScrollController _scrollController = ScrollController();

  bool _isAutoScrolling = false;
  bool _isUserScrolling = false;
  Timer? _autoScrollTimer;
  double _scrollSpeed = 0.35;

  String _selectedReciterId = 'alafasy';
  final Map<String, String> _reciters = {
    'alafasy': 'الشيخ مشاري العفاسي',
    'abdulbasit': 'الشيخ عبد الباسط عبد الصمد',
    'sudais': 'الشيخ عبد الرحمن السديس',
    'husary': 'الشيخ محمود خليل الحصري',
    'minshawi': 'الشيخ محمد صديق المنشاوي',
    'maher': 'الشيخ ماهر المعيقلي',
    'ghamdi': 'الشيخ سعد الغامدي',
    'ajamy': 'الشيخ أحمد العجمي',
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadPreferences();
    
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {});
      }
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _playingVerse = null;
            _isPlayingFullSurah = false;
          });
          _stopAutoScroll();
        }
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedReciterId = prefs.getString('preferred_reciter') ?? 'alafasy';
      _themeModeIndex = prefs.getInt('quran_theme_mode_index') ?? 0;
      _fontSize = prefs.getDouble('quran_font_size') ?? 22.0;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_reciter', _selectedReciterId);
    await prefs.setInt('quran_theme_mode_index', _themeModeIndex);
    await prefs.setDouble('quran_font_size', _fontSize);
  }

  void _cycleThemeMode() {
    setState(() {
      _themeModeIndex = (_themeModeIndex + 1) % 3;
    });
    _savePreferences();
    
    String themeName = '';
    if (_themeModeIndex == 0) themeName = '☀️ الوضع النهاري العادي';
    if (_themeModeIndex == 1) themeName = '📜 الوضع الورقي الدافئ (Sepia)';
    if (_themeModeIndex == 2) themeName = '🌙 وضع السكينة الليلي (OLED Black)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(themeName), backgroundColor: Colors.teal, duration: const Duration(milliseconds: 1200)),
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (_scrollController.hasClients && _isAutoScrolling) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;
        
        if (currentScroll >= maxScroll) {
          _stopAutoScroll();
        } else if (!_isUserScrolling) {
          _scrollController.jumpTo(currentScroll + _scrollSpeed);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    if (mounted) {
      setState(() => _isAutoScrolling = false);
    }
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      setState(() => _isAutoScrolling = true);
      _startAutoScroll();
    }
  }

  void _showSpeedSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('⚡ ضبط سرعة التمرير', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<double>(
                title: const Text('بطيء للغاية (للتدبر العميق)', style: TextStyle(color: Colors.white)),
                value: 0.2,
                groupValue: _scrollSpeed,
                activeColor: Colors.tealAccent,
                onChanged: (val) {
                  setState(() => _scrollSpeed = val!);
                  if (_isAutoScrolling) _startAutoScroll();
                  Navigator.pop(context);
                },
              ),
              RadioListTile<double>(
                title: const Text('هادئ ومثالي (مناسب للشيخ)', style: TextStyle(color: Colors.white)),
                value: 0.35,
                groupValue: _scrollSpeed,
                activeColor: Colors.tealAccent,
                onChanged: (val) {
                  setState(() => _scrollSpeed = val!);
                  if (_isAutoScrolling) _startAutoScroll();
                  Navigator.pop(context);
                },
              ),
              RadioListTile<double>(
                title: const Text('متوسط (قراءة أسرع قليلًا)', style: TextStyle(color: Colors.white)),
                value: 0.6,
                groupValue: _scrollSpeed,
                activeColor: Colors.tealAccent,
                onChanged: (val) {
                  setState(() => _scrollSpeed = val!);
                  if (_isAutoScrolling) _startAutoScroll();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveColoredBookmark(int verseNumber, String colorTag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmark_${widget.surahNumber}_$verseNumber', colorTag);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔖 تم حفظ علامة مرجعية ($colorTag) للآية ($verseNumber)'), backgroundColor: Colors.teal),
      );
    }
  }

  void _showVerseShareCard(int verseNumber) {
    String verseText = quran.getVerse(widget.surahNumber, verseNumber);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('🌟 بطاقة مشاركة الآية', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('سورة ${widget.surahName} - الآية ($verseNumber)', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  '"$verseText"',
                  style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                const Text('من تطبيق المصحف الشريف 📖', style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📋 تمت محاكاة نسخ النص والبطاقة بنجاح!'), backgroundColor: Colors.teal),
                );
              },
              child: const Text('نسخ ومشاركة'),
            ),
          ],
        );
      },
    );
  }

  void _showAIRelectionDialog(int verseNumber) {
    String verseText = quran.getVerse(widget.surahNumber, verseNumber);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Text('مساعد التدبر (الآية $verseNumber)', style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('"$verseText"', style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic), textAlign: TextAlign.right),
                const Divider(color: Colors.white24, height: 20),
                const Text('💡 لمحات وعبر إيمانية:', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  '• لمحة بلاغية: دقة اختيار الألفاظ القرآنية لغرس الطمأنينة في القلب.\n'
                  '• وقفة تدبرية: كيف تجعل هذه الآية منهجاً عملياً في يومك وسلوكك؟\n'
                  '• رسالة ربانية: الله سبحانه وتعالى يخاطب قلبك بهذا النص لتجديد اليقين.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => Navigator.pop(context),
              child: const Text('حفظ في الخواطر'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addVerseNote(int verseNumber) async {
    TextEditingController noteController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    String noteKey = 'note_${widget.surahNumber}_$verseNumber';
    noteController.text = prefs.getString(noteKey) ?? '';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: Text('📝 خواطر وتدبر الآية ($verseNumber)', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: noteController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظتك أو خاطرتك حول الآية هنا...',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF111827),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                await prefs.setString(noteKey, noteController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✨ تم حفظ ملاحظتك على الآية بنجاح'), backgroundColor: Colors.teal),
                );
              },
              child: const Text('حفظ الخاطرة'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveBookmarkAndSyncKhatma(int verseNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah', widget.surahNumber);
    await prefs.setInt('last_verse', verseNumber);
    await prefs.setString('last_surah_name', widget.surahName);

    int estimatedPage = (widget.surahNumber * 5).clamp(1, 604);
    await prefs.setInt('khatma_exact_page', estimatedPage);
    
    int currentDay = prefs.getInt('khatma_current_day') ?? 1;
    int currentStreak = prefs.getInt('khatma_streak') ?? 0;
    await prefs.setInt('khatma_current_day', currentDay + 1);
    await prefs.setInt('khatma_streak', currentStreak + 1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📌 تم حفظ الفاصل عند الآية ($verseNumber) وتحديث الختمة (صفحة $estimatedPage)'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _playVerseAudio(int verseNumber) async {
    try {
      await _audioPlayer.stop();
      String audioUrl = quran.getAudioURLByVerse(widget.surahNumber, verseNumber);
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      
      setState(() {
        _playingVerse = verseNumber;
        _isPlayingFullSurah = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تأكد من الاتصال بالإنترنت للاستماع للصوت')),
        );
      }
    }
  }

  Future<void> _togglePlayFullSurah() async {
    try {
      if (_isPlayingFullSurah && _audioPlayer.playing) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingFullSurah = false;
          _playingVerse = null;
        });
      } else {
        await _audioPlayer.stop();
        String formattedSurah = widget.surahNumber.toString().padLeft(3, '0');
        String fullSurahUrl = 'https://server8.mp3quran.net/afs/$formattedSurah.mp3';
        
        if (_selectedReciterId == 'abdulbasit') {
          fullSurahUrl = 'https://server7.mp3quran.net/basit/Almusshaf-Almojawwad/$formattedSurah.mp3';
        } else if (_selectedReciterId == 'sudais') {
          fullSurahUrl = 'https://server11.mp3quran.net/sds/$formattedSurah.mp3';
        } else if (_selectedReciterId == 'husary') {
          fullSurahUrl = 'https://server13.mp3quran.net/husr/$formattedSurah.mp3';
        }

        await _audioPlayer.setUrl(fullSurahUrl);
        await _audioPlayer.play();
        
        setState(() {
          _isPlayingFullSurah = true;
          _playingVerse = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل السورة كاملة')),
        );
      }
    }
  }

  void _showReciterSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('🎙️ اختر القارئ المفضل', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _reciters.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                  value: entry.key,
                  groupValue: _selectedReciterId,
                  activeColor: Colors.tealAccent,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReciterId = val);
                      _savePreferences();
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showVerseOptions(int verseNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الآية ($verseNumber) - سورة ${widget.surahName}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(color: Colors.white24, height: 20),
              ListTile(
                leading: const Icon(Icons.psychology, color: Colors.amberAccent),
                title: const Text('مساعد التدبر ولمحات الآية 🧠', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showAIRelectionDialog(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.tealAccent),
                title: const Text('استماع للآية الصوتية', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _playVerseAudio(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.tealAccent),
                title: const Text('التفسير الميسر ومعاني الكلمات', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showTafsirBottomSheet(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.amberAccent),
                title: const Text('إضافة خاطرة أو ملاحظة على الآية 📝', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _addVerseNote(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.cyanAccent),
                title: const Text('مشاركة الآية كبطاقة تصميم 🌟', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showVerseShareCard(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.greenAccent),
                title: const Text('وضع علامة مرجعية ملونة (🟢 حفظ / 🟡 تدبر)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _saveColoredBookmark(verseNumber, 'تدبر وتأمل');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add, color: Colors.amber),
                title: const Text('حفظ كفاصل قراءة وتحديث الختمة 📖', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _saveBookmarkAndSyncKhatma(verseNumber);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTafsirBottomSheet(int verseNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📖 التفسير الميسر للآية ($verseNumber)', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'قال تعالى: "${quran.getVerse(widget.surahNumber, verseNumber)}"',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 15, height: 1.6, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'تفسير الآية الكريمة رقم ($verseNumber) من سورة ${widget.surahName}:\n'
                            'هذه الآية ترشد إلى عظم الهدايات القرآنية ووجوب التدبر والعمل بأحكام كتاب الله سبحانه وتعالى.',
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.8),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalVerses = quran.getVerseCount(widget.surahNumber);
    String place = quran.getPlaceOfRevelation(widget.surahNumber) == 'Makkah' ? 'مكية' : 'مدنية';

    Color bgColor = const Color(0xFFFBF8F1);
    Color appBarBg = const Color(0xFFEFE8D2);
    Color textColor = Colors.black87;
    Color headerBg = const Color(0xFFF3EFE6);
    Color boxBg = Colors.white;
    IconData themeIcon = Icons.light_mode;

    if (_themeModeIndex == 1) {
      bgColor = const Color(0xFFF4ECD8);
      appBarBg = const Color(0xFFE2D4B7);
      textColor = const Color(0xFF3E2723);
      headerBg = const Color(0xFFEADCC2);
      boxBg = const Color(0xFFFAF6ED);
      themeIcon = Icons.menu_book;
    } else if (_themeModeIndex == 2) {
      bgColor = Colors.black;
      appBarBg = const Color(0xFF121212);
      textColor = Colors.white70;
      headerBg = const Color(0xFF1E1E1E);
      boxBg = const Color(0xFF0D0D0D);
      themeIcon = Icons.dark_mode;
    }

    bool isAudioActive = _audioPlayer.playing || _isPlayingFullSurah || _playingVerse != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _isZenMode ? null : AppBar(
        title: Text('سورة ${widget.surahName}', style: TextStyle(color: _themeModeIndex == 2 ? Colors.white : textColor, fontWeight: FontWeight.bold)),
        backgroundColor: appBarBg,
        iconTheme: IconThemeData(color: _themeModeIndex == 2 ? Colors.white : textColor),
        actions: [
          IconButton(
            icon: Icon(
              _isMemorizationMode ? Icons.visibility_off : Icons.visibility,
              color: _isMemorizationMode ? Colors.amberAccent : Colors.tealAccent,
            ),
            tooltip: _isMemorizationMode ? 'إلغاء وضع التسميع' : 'وضع تسميع ومراجعة الحفظ',
            onPressed: () => setState(() => _isMemorizationMode = !_isMemorizationMode),
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.amberAccent),
            tooltip: 'وضع التدبر (إخفاء المشتتات)',
            onPressed: () => setState(() => _isZenMode = true),
          ),
          IconButton(
            icon: Icon(themeIcon, color: _themeModeIndex == 2 ? Colors.amberAccent : Colors.tealAccent),
            tooltip: 'تبديل وضع السكينة (نهاري / ورقي دافئ / ليلي أسود)',
            onPressed: _cycleThemeMode,
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.tealAccent),
            tooltip: 'اختيار القارئ',
            onPressed: _showReciterSelectionDialog,
          ),
          IconButton(
            icon: Icon(_isPlayingFullSurah ? Icons.stop_circle : Icons.play_circle_filled, color: Colors.tealAccent),
            onPressed: _togglePlayFullSurah,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.tealAccent),
            onPressed: () {
              setState(() => _fontSize = math.min(_fontSize + 2, 36.0));
              _savePreferences();
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.tealAccent),
            onPressed: () {
              setState(() => _fontSize = math.max(_fontSize - 2, 16.0));
              _savePreferences();
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isZenMode)
              FloatingActionButton.extended(
                heroTag: 'exitZenBtn',
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                onPressed: () => setState(() => _isZenMode = false),
                icon: const Icon(Icons.fullscreen_exit),
                label: const Text('إظهار القوائم'),
              ),
            if (!_isZenMode) ...[
              FloatingActionButton.small(
                heroTag: 'speedBtn',
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.tealAccent,
                onPressed: _showSpeedSelectionDialog,
                child: const Icon(Icons.speed, size: 20),
              ),
              const SizedBox(width: 10),
            ],
            FloatingActionButton.extended(
              heroTag: 'autoScrollBtn',
              backgroundColor: _isAutoScrolling ? Colors.redAccent : Colors.teal,
              foregroundColor: Colors.white,
              onPressed: _toggleAutoScroll,
              icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow_rounded, size: 24),
              label: Text(_isAutoScrolling ? 'إيقاف التمرير' : 'قراءة هادئة ومتأنية', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isAudioActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                border: Border(top: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.headphones, color: Colors.tealAccent, size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('سورة ${widget.surahName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_reciters[_selectedReciterId] ?? '', style: const TextStyle(color: Colors.tealAccent, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_audioPlayer.playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.tealAccent, size: 36),
                        onPressed: () {
                          if (_audioPlayer.playing) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop_rounded, color: Colors.redAccent, size: 30),
                        onPressed: () async {
                          await _audioPlayer.stop();
                          setState(() {
                            _playingVerse = null;
                            _isPlayingFullSurah = false;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () {
          if (_isZenMode) setState(() => _isZenMode = false);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              setState(() => _isUserScrolling = true);
            } else if (notification is ScrollEndNotification) {
              setState(() => _isUserScrolling = false);
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                if (!_isZenMode) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: headerBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _themeModeIndex == 2 ? Colors.white24 : Colors.amber.shade600, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'سورة ${widget.surahName}',
                          style: TextStyle(
                            color: _themeModeIndex == 2 ? Colors.amberAccent : textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$place • عدد الآيات: $totalVerses • القارئ: ${_reciters[_selectedReciterId]}',
                          style: TextStyle(
                            color: _themeModeIndex == 2 ? Colors.white70 : textColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (widget.surahNumber != 1 && widget.surahNumber != 9)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      quran.basmala,
                      style: TextStyle(
                        color: _themeModeIndex == 2 ? Colors.tealAccent : Colors.teal.shade900,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: boxBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _themeModeIndex == 2 ? Colors.white10 : Colors.brown.shade200),
                  ),
                  child: Wrap(
                    textDirection: TextDirection.rtl,
                    alignment: WrapAlignment.start,
                    children: List.generate(totalVerses, (index) {
                      int verseNumber = index + 1;
                      String verseText = quran.getVerse(widget.surahNumber, verseNumber);
                      
                      String displayedText = _isMemorizationMode 
                          ? '•••••••••••• (اضغط للاختبار)' 
                          : verseText;

                      bool isPlayingThis = _playingVerse == verseNumber && _audioPlayer.playing;
                      bool isTargetVerse = widget.initialVerse == verseNumber;

                      return GestureDetector(
                        onTap: () => _showVerseOptions(verseNumber),
                        child: Container(
                          color: isTargetVerse 
                              ? Colors.teal.shade800.withValues(alpha: 0.4) 
                              : (isPlayingThis ? Colors.teal.shade900.withValues(alpha: 0.6) : Colors.transparent),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          child: Text(
                            '$displayedText ﴿$verseNumber﴾ ',
                            style: TextStyle(
                              color: _isMemorizationMode ? Colors.amberAccent : (isTargetVerse ? Colors.tealAccent : textColor),
                              fontSize: _fontSize,
                              height: 2.3,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}