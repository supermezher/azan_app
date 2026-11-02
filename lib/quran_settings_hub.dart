import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class QuranSettingsHubScreen extends StatefulWidget {
  const QuranSettingsHubScreen({super.key});

  @override
  State<QuranSettingsHubScreen> createState() => _QuranSettingsHubScreenState();
}

class _QuranSettingsHubScreenState extends State<QuranSettingsHubScreen> {
  // متغيرات الإعدادات
  bool _dailyReminder = true;
  bool _fridayKahfReminder = true;
  bool _keepScreenOn = true;
  String _reminderTime = '20:00';
  String _defaultReciter = 'alafasy';
  String _defaultTafsir = 'الميسر';
  double _globalFontSize = 22.0;

  final Map<String, String> _recitersList = {
    'alafasy': 'الشيخ مشاري العفاسي',
    'abdulbasit': 'الشيخ عبد الباسط عبد الصمد',
    'sudais': 'الشيخ عبد الرحمن السديس',
    'husary': 'الشيخ محمود خليل الحصري',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('setting_daily_reminder') ?? true;
      _fridayKahfReminder = prefs.getBool('setting_friday_kahf') ?? true;
      _keepScreenOn = prefs.getBool('setting_keep_screen_on') ?? true;
      _reminderTime = prefs.getString('setting_reminder_time') ?? '20:00';
      _defaultReciter = prefs.getString('preferred_reciter') ?? 'alafasy';
      _defaultTafsir = prefs.getString('setting_default_tafsir') ?? 'الميسر';
      _globalFontSize = prefs.getDouble('quran_font_size') ?? 22.0;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_reminderTime.split(':')[0]),
        minute: int.parse(_reminderTime.split(':')[1]),
      ),
    );
    if (picked != null) {
      String formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = formattedTime);
      _saveSetting('setting_reminder_time', formattedTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⏰ تم ضبط وقت التذكير اليومي على: $formattedTime'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  // 📦 دالة تصدير النسخة الاحتياطية
  Future<void> _exportBackup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, dynamic> backupData = {};

    for (String key in keys) {
      backupData[key] = prefs.get(key);
    }

    String jsonString = json.encode(backupData);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('📦 النسخة الاحتياطية (JSON)', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 تم نسخ النسخة الاحتياطية إلى الحافظة بنجاح'), backgroundColor: Colors.teal),
              );
            },
            child: const Text('نسخ البيانات'),
          ),
        ],
      ),
    );
  }

  // 📥 دالة استعادة النسخة الاحتياطية
  void _showImportDialog(BuildContext context) {
    TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('📥 استعادة النسخة الاحتياطية', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الصق نص النسخة الاحتياطية (JSON) هنا لاستعادة بياناتك:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: importController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'الصق النص هنا...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF111827),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              try {
                Map<String, dynamic> data = json.decode(importController.text);
                final prefs = await SharedPreferences.getInstance();
                
                for (var entry in data.entries) {
                  var val = entry.value;
                  if (val is bool) await prefs.setBool(entry.key, val);
                  if (val is int) await prefs.setInt(entry.key, val);
                  if (val is double) await prefs.setDouble(entry.key, val);
                  if (val is String) await prefs.setString(entry.key, val);
                  if (val is List) await prefs.setString(entry.key, json.encode(val));
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✨ تمت استعادة كافة البيانات والختمات بنجاح!'), backgroundColor: Colors.teal),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ خطأ في تنسيق النص، تأكد من صحة الكود'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('استعادة وتطبيق', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('⚙️ الإعدادات والتنبيهات المتقدمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --------------------------------------------------
          // 1. قسم الإشعارات والتنبيهات
          // --------------------------------------------------
          const Text('🔔 التنبيهات والإشعارات الذكية', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('تذكير الورد اليومي', style: TextStyle(color: Colors.white)),
            subtitle: const Text('إرسال تنبيه لطيف لقراءة الورد في الوقت المحدد', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _dailyReminder,
            activeColor: Colors.tealAccent,
            onChanged: (val) {
              setState(() => _dailyReminder = val);
              _saveSetting('setting_daily_reminder', val);
            },
          ),
          if (_dailyReminder)
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.tealAccent),
              title: const Text('وقت التذكير اليومي', style: TextStyle(color: Colors.white)),
              subtitle: Text('الوقت الحالي: $_reminderTime', style: const TextStyle(color: Colors.white54)),
              trailing: TextButton(
                onPressed: () => _selectReminderTime(context),
                child: const Text('تغيير الوقت', style: TextStyle(color: Colors.tealAccent)),
              ),
            ),
          SwitchListTile(
            title: const Text('تذكير سورة الكهف يوم الجمعة', style: TextStyle(color: Colors.white)),
            subtitle: const Text('تنبيه أسبوعي مبارك لقراءة سورة الكهف', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _fridayKahfReminder,
            activeColor: Colors.tealAccent,
            onChanged: (val) {
              setState(() => _fridayKahfReminder = val);
              _saveSetting('setting_friday_kahf', val);
            },
          ),

          const Divider(color: Colors.white24, height: 30),

          // --------------------------------------------------
          // 2. قسم شاشة القراءة وحجم الخط
          // --------------------------------------------------
          const Text('📱 إعدادات الخط وحجم القراءة', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          
          Card(
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('حجم الخط الافتراضي للآيات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${_globalFontSize.toInt()} pt', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _globalFontSize,
                    min: 16.0,
                    max: 38.0,
                    divisions: 11,
                    activeColor: Colors.amberAccent,
                    inactiveColor: Colors.white24,
                    label: '${_globalFontSize.toInt()}',
                    onChanged: (newSize) {
                      setState(() => _globalFontSize = newSize);
                      _saveSetting('quran_font_size', newSize);
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '﴿الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ﴾',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _globalFontSize,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('إبقاء الشاشة مضاءة أثناء القراءة', style: TextStyle(color: Colors.white)),
            subtitle: const Text('يمنع إطفاء الشاشة التلقائي أثناء تلاوة القرآن', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _keepScreenOn,
            activeColor: Colors.amberAccent,
            onChanged: (val) {
              setState(() => _keepScreenOn = val);
              _saveSetting('setting_keep_screen_on', val);
            },
          ),

          const Divider(color: Colors.white24, height: 30),

          // --------------------------------------------------
          // 3. قسم الصوتيات والتلاوة الافتراضية
          // --------------------------------------------------
          const Text('🎙️ تفضيلات التلاوة الصوتية', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('القارئ الافتراضي الأساسي', style: TextStyle(color: Colors.white)),
            subtitle: Text(_recitersList[_defaultReciter] ?? '', style: const TextStyle(color: Colors.white54)),
            trailing: DropdownButton<String>(
              value: _defaultReciter,
              dropdownColor: const Color(0xFF1F2937),
              style: const TextStyle(color: Colors.tealAccent),
              items: _recitersList.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() => _defaultReciter = newVal);
                  _saveSetting('preferred_reciter', newVal);
                }
              },
            ),
          ),

          const Divider(color: Colors.white24, height: 30),

          // --------------------------------------------------
          // 4. قسم التفاسير المعتمدة
          // --------------------------------------------------
          const Text('📚 مكتبة التفاسير', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('التفسير المعتمد الافتراضي', style: TextStyle(color: Colors.white)),
            subtitle: Text('التفسير الحالي: $_defaultTafsir', style: const TextStyle(color: Colors.white54)),
            trailing: DropdownButton<String>(
              value: _defaultTafsir,
              dropdownColor: const Color(0xFF1F2937),
              style: const TextStyle(color: Colors.tealAccent),
              items: ['الميسر', 'السعدي', 'ابن كثير', 'البغوي'].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() => _defaultTafsir = newVal);
                  _saveSetting('setting_default_tafsir', newVal);
                }
              },
            ),
          ),

          const Divider(color: Colors.white24, height: 30),

          // --------------------------------------------------
          // 5. قسم إدارة البيانات والنسخ الاحتياطي (المطور)
          // --------------------------------------------------
          const Text('💾 إدارة البيانات والنسخ الاحتياطي', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          
          // زر تصدير النسخة
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Colors.tealAccent),
            title: const Text('تصدير نسخة احتياطية (Backup)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('حفظ الختمات، الخواطر، والعلامات في نص', style: TextStyle(color: Colors.white54, fontSize: 11)),
            onTap: () => _exportBackup(context),
          ),

          // زر استعادة النسخة
          ListTile(
            leading: const Icon(Icons.cloud_download, color: Colors.amberAccent),
            title: const Text('استعادة نسخة احتياطية (Restore)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('استرجاع بياناتك من نص محفوظ مسبقاً', style: TextStyle(color: Colors.white54, fontSize: 11)),
            onTap: () => _showImportDialog(context),
          ),

          // زر التصفير الآمن
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            title: const Text('إعادة ضبط وتصفير بيانات الختمة', style: TextStyle(color: Colors.white)),
            subtitle: const Text('إعادة العدادات والصفحات للبداية', style: TextStyle(color: Colors.white54, fontSize: 11)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1F2937),
                  title: const Text('⚠️ تنبيه', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  content: const Text('هل أنت متأكد من رغبتك في إعادة تعيين بيانات الختمة؟', style: TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('khatma_exact_page');
                        await prefs.remove('khatma_streak');
                        await prefs.remove('khatma_current_day');
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔄 تم إعادة تعيين البيانات بنجاح'), backgroundColor: Colors.red),
                        );
                      },
                      child: const Text('تأكيد التصفير'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}