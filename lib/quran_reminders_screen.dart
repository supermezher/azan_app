import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranRemindersScreen extends StatefulWidget {
  const QuranRemindersScreen({super.key});

  @override
  State<QuranRemindersScreen> createState() => _QuranRemindersScreenState();
}

class _QuranRemindersScreenState extends State<QuranRemindersScreen> {
  bool _dailyReminderEnabled = true;
  bool _fridayKahfReminder = true;
  String _selectedWirdAmount = 'صفحة واحدة (ورد خفيف)';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 30);

  final List<String> _wirdOptions = [
    'صفحة واحدة (ورد خفيف)',
    'ربع حزب (مناسب للتدبر)',
    'حزب كامل (للجديّن)',
    'جزء كامل (ختمة في شهر)',
  ];

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
      _fridayKahfReminder = prefs.getBool('friday_kahf_reminder') ?? true;
      _selectedWirdAmount = prefs.getString('selected_wird_amount') ?? 'صفحة واحدة (ورد خفيف)';
      
      int hour = prefs.getInt('reminder_hour') ?? 6;
      int minute = prefs.getInt('reminder_minute') ?? 30;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setBool('friday_kahf_reminder', _fridayKahfReminder);
    await prefs.setString('selected_wird_amount', _selectedWirdAmount);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ تم حفظ إعدادات التنبيهات والورد بنجاح'), backgroundColor: Colors.teal),
      );
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      _saveReminderSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('⏰ التنبيهات والورد اليومي الذكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اجعل لك رفيقاً لا يفارقك', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('التنبيهات المنتظمة تضمن لك ختمة مباركة واستمرارية بلا انقطاع.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('📖 مقدار الورد اليومي المستهدف', style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: _wirdOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(option, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    value: option,
                    groupValue: _selectedWirdAmount,
                    activeColor: Colors.tealAccent,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedWirdAmount = val);
                        _saveReminderSettings();
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('🔔 إعدادات التنبيه والإشعارات', style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('تنبيه الورد اليومي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('تذكير يومي في الوقت المحدد لقراءة وردك', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _dailyReminderEnabled,
                    activeThumbColor: Colors.tealAccent,
                    onChanged: (val) {
                      setState(() => _dailyReminderEnabled = val);
                      _saveReminderSettings();
                    },
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.tealAccent),
                    title: const Text('وقت التنبيه المفضل', style: TextStyle(color: Colors.white)),
                    trailing: Text(
                      _reminderTime.format(context),
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () => _selectTime(context),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  SwitchListTile(
                    title: const Text('تذكير سورة الكهف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('تنبيه خاص كل يوم جمعة لقراءة سورة الكهف', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _fridayKahfReminder,
                    activeThumbColor: Colors.tealAccent,
                    onChanged: (val) {
                      setState(() => _fridayKahfReminder = val);
                      _saveReminderSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}