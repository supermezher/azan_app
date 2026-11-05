import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/surah_detail_screen.dart';

class QuranBookmarksScreen extends StatefulWidget {
  const QuranBookmarksScreen({super.key});

  @override
  State<QuranBookmarksScreen> createState() => _QuranBookmarksScreenState();
}

class _QuranBookmarksScreenState extends State<QuranBookmarksScreen> {
  var _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    var tempBookmarks = [];

    for (String key in keys) {
      if (key.startsWith('bookmark_')) {
        // التحقق الآمن من نوع البيانات لمنع خطأ الـ Null
        Object? rawValue = prefs.get(key);
        String tag = rawValue != null ? rawValue.toString() : 'علامة مرجعية';
        
        final parts = key.split('_');
        if (parts.length >= 3) {
          int? surah = int.tryParse(parts[1]);
          int? verse = int.tryParse(parts[2]);
          
          if (surah != null && verse != null) {
            tempBookmarks.add({
              'key': key,
              'surah': surah,
              'verse': verse,
              'tag': tag,
            });
          }
        }
      }
    }

    setState(() {
      _bookmarks = tempBookmarks;
    });
  }

  // دالة حذف العلامة المرجعية بأمان
  Future<void> _deleteBookmark(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await _loadBookmarks(); // إعادة تحميل القائمة لتحديث الواجهة

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ تم حذف العلامة المرجعية بنجاح'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('🔖 مركز العلامات والمفضلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _bookmarks.isEmpty
          ? const Center(
              child: Text(
                'لا توجد علامات مرجعية محفوظة.\nاضغط مطولاً على أي آية وضع علامة ملونة لتظهر هنا!',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final bm = _bookmarks[index];
                return Card(
                  color: const Color(0xFF1F2937),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.bookmark, color: Colors.tealAccent),
                    ),
                    title: Text('سورة رقم (${bm['surah']}) - الآية (${bm['verse']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('التصنيف: ${bm['tag']}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'حذف العلامة',
                          onPressed: () => _deleteBookmark(bm['key']),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurahDetailScreen(
                            surahNumber: bm['surah'],
                            surahName: 'السورة رقم ${bm['surah']}',
                            initialVerse: bm['verse'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}