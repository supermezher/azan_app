import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReadSurah = prefs.getInt('last_surah');
      _lastReadVerse = prefs.getInt('last_verse');
      _lastReadSurahName = prefs.getString('last_surah_name') ?? '';
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'السور (114)'),
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
                  subtitle: Text('$place - عدد آياتها: $versesCount', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
// شاشة القراءة المتقدمة
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
  bool _isDarkMode = true;
  double _fontSize = 20.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingVerse;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _playingVerse = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveBookmark(int verseNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah', widget.surahNumber);
    await prefs.setInt('last_verse', verseNumber);
    await prefs.setString('last_surah_name', widget.surahName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📌 تم حفظ فاصل القراءة عند الآية ($verseNumber) من سورة ${widget.surahName}'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _playVerseAudio(int verseNumber) async {
    try {
      if (_playingVerse == verseNumber && _audioPlayer.playing) {
        await _audioPlayer.stop();
        setState(() => _playingVerse = null);
      } else {
        String audioUrl = quran.getAudioURLByVerse(widget.surahNumber, verseNumber);
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        setState(() => _playingVerse = verseNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تأكد من الاتصال بالإنترنت للاستماع للصوت')),
        );
      }
    }
  }

  void _showTafsirBottomSheet(int verseNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📖 تفسير الآية ($verseNumber) - سورة ${widget.surahName}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'قال تعالى: "${quran.getVerse(widget.surahNumber, verseNumber)}"\n\nالتفسير الميسر: يتناول المعنى الشريف للآية الكريمة، تدبراً وحكمة لتقريب فهم الآيات المباركة.',
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalVerses = quran.getVerseCount(widget.surahNumber);

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('سورة ${widget.surahName}', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
        backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFEFE8D2),
        iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.tealAccent),
            tooltip: 'تكبير الخط',
            onPressed: () => setState(() => _fontSize = math.min(_fontSize + 2, 32.0)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.tealAccent),
            tooltip: 'تصغير الخط',
            onPressed: () => setState(() => _fontSize = math.max(_fontSize - 2, 14.0)),
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.tealAccent),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: totalVerses + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            if (widget.surahNumber != 1 && widget.surahNumber != 9) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
                child: Text(
                  quran.basmala,
                  style: TextStyle(color: _isDarkMode ? Colors.tealAccent : Colors.teal.shade900, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          int verseNumber = index;
          bool isPlayingThis = _playingVerse == verseNumber && _audioPlayer.playing;
          bool isTargetVerse = widget.initialVerse == verseNumber;

          return Card(
            color: isTargetVerse 
                ? Colors.teal.shade800 
                : (isPlayingThis ? Colors.teal.shade900 : (_isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF4ECD8))),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isTargetVerse ? const BorderSide(color: Colors.tealAccent, width: 2) : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    '${quran.getVerse(widget.surahNumber, verseNumber)} ﴿$verseNumber﴾',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: _fontSize,
                      height: 2.1,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(isPlayingThis ? Icons.stop_circle : Icons.volume_up, color: Colors.tealAccent),
                        tooltip: 'استماع للآية',
                        onPressed: () => _playVerseAudio(verseNumber),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu_book, color: Colors.tealAccent),
                        tooltip: 'التفسير الميسر',
                        onPressed: () => _showTafsirBottomSheet(verseNumber),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_add, color: Colors.amber),
                        tooltip: 'حفظ كفاصل قراءة',
                        onPressed: () => _saveBookmark(verseNumber),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}