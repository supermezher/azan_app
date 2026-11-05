import 'package:flutter/material.dart';
import 'quran_reminders_screen.dart'; // استدعاء شاشة التنبيهات والورد اليومي

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _dailyReminder = true;
  bool _kahfReminder = true;
  bool _keepScreenOn = true;
  double _fontSize = 24.0;
  String _selectedRecitor = 'الشيخ مشاري العفاسي';
  String _selectedTafseer = 'الميسر';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('الإعدادات والتنبيهات المتقدمة ⚙️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ----------------- قسم التنبيهات والإشعارات الذكية -----------------
          const Text('🔔 التنبيهات والإشعارات الذكية', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('تذكير الورد اليومي', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('إرسال تنبيه لطيف لقراءة الورد في الوقت المحدد', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _dailyReminder,
                  activeThumbColor: Colors.tealAccent,
                  onChanged: (val) => setState(() => _dailyReminder = val),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.tealAccent),
                  title: const Text('وقت وتفاصيل التذكير الذكي', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('اضغط لتخصيص الورد وأوقات التنبيه بدقة', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.tealAccent, size: 16),
                  onTap: () {
                    // الانتقال المباشر إلى شاشة إعدادات التنبيهات والورد اليومي
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuranRemindersScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: const Text('تذكير سورة الكهف يوم الجمعة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('تنبيه أسبوعي مبارك لقراءة سورة الكهف', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _kahfReminder,
                  activeThumbColor: Colors.tealAccent,
                  onChanged: (val) => setState(() => _kahfReminder = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ----------------- قسم إعدادات الخط وحجم القراءة -----------------
          const Text('📱 إعدادات الخط وحجم القراءة', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('حجم الخط الافتراضي للآيات', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('${_fontSize.toInt()} pt', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _fontSize,
                  min: 16.0,
                  max: 36.0,
                  divisions: 10,
                  activeColor: Colors.amberAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) => setState(() => _fontSize = val),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '﴿الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ﴾',
                    style: TextStyle(color: Colors.white, fontSize: _fontSize),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إبقاء الشاشة مضاءة أثناء القراءة', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('يمنع إطفاء الشاشة التلقائي أثناء تلاوة القرآن', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _keepScreenOn,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) => setState(() => _keepScreenOn = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ----------------- تفضيلات التلاوة الصوتية -----------------
          const Text('🎧 تفضيلات التلاوة الصوتية', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('القارئ الافتراضي الأساسي', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(_selectedRecitor, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: DropdownButton<String>(
                value: _selectedRecitor,
                dropdownColor: const Color(0xFF1F2937),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                items: ['الشيخ مشاري العفاسي', 'الشيخ عبد الرحمن السديس', 'الشيخ ماهر المعيقلي'].map((recitor) {
                  return DropdownMenuItem<String>(
                    value: recitor,
                    child: Text(recitor),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRecitor = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ----------------- مكتبة التفاسير -----------------
          const Text('📚 مكتبة التفاسير', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('التفسير المعتمد الافتراضي', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('التفسير الحالي: $_selectedTafseer', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: DropdownButton<String>(
                value: _selectedTafseer,
                dropdownColor: const Color(0xFF1F2937),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                items: ['الميسر', 'ابن كثير', 'السعدي'].map((tafseer) {
                  return DropdownMenuItem<String>(
                    value: tafseer,
                    child: Text(tafseer),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTafseer = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ----------------- إدارة البيانات والنسخ الاحتياطي -----------------
          const Text('💾 إدارة البيانات والنسخ الاحتياطي', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: Colors.tealAccent),
                  title: const Text('تصدير نسخة احتياطية (Backup)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('حفظ الختمات، الخواطر، والعلامات في نص', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download, color: Colors.amberAccent),
                  title: const Text('استعادة نسخة احتياطية (Restore)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('استرجاع بياناتك من نص محفوظ مسبقاً', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('إعادة ضبط وتصفير بيانات الختمة', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('إعادة العدادات والصفحات للبداية', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}