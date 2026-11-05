import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../screens/surah_detail_screen.dart';

// --- 1. تبويب السور ---
class QuranListTab extends StatefulWidget {
  const QuranListTab({super.key});

  @override
  State<QuranListTab> createState() => _QuranListTabState();
}

class _QuranListTabState extends State<QuranListTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- 2. تبويب الأجزاء ---
class QuranJuzTab extends StatelessWidget {
  const QuranJuzTab({super.key});

  @override
  Widget build(BuildContext context) {
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
}

// --- 3. تبويب البحث المتقدم داخل الآيات ---
class QuranSearchTab extends StatefulWidget {
  const QuranSearchTab({super.key});

  @override
  State<QuranSearchTab> createState() => _QuranSearchTabState();
}

class _QuranSearchTabState extends State<QuranSearchTab> {
  String _searchQuery = '';
  final List _searchResults = [];

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