import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_khatma_screen.dart';
import 'quran_analytics_screen.dart';
import 'quran_bookmarks_screen.dart';
import 'quran_settings_hub.dart';
import 'widgets/quran_list_tabs.dart';
import 'screens/surah_detail_screen.dart';

class QuranListScreen extends StatefulWidget {
  const QuranListScreen({super.key});

  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}

class _QuranListScreenState extends State<QuranListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _lastReadSurah;
  int? _lastReadVerse;
  String _lastReadSurahName = '';

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
      Object? nameObj = prefs.get('last_surah_name');
      _lastReadSurahName = nameObj != null ? nameObj.toString() : '';
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const QuranBookmarksScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.tealAccent),
            tooltip: 'الإعدادات والتنبيهات',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdvancedSettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.tealAccent),
            tooltip: 'خطة الختمة والورد اليومي',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const QuranKhatmaScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.tealAccent),
            tooltip: 'لوحة إحصاءات القراءة والختمات',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const QuranAnalyticsScreen()));
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
                        'سورة $_lastReadSurahName الآية ($_lastReadVerse)',
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
              children: const [
                QuranListTab(),
                QuranJuzTab(),
                QuranSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}