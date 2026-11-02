import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuranKhatmaScreen extends StatefulWidget {
  const QuranKhatmaScreen({super.key});

  @override
  State<QuranKhatmaScreen> createState() => _QuranKhatmaScreenState();
}

class _QuranKhatmaScreenState extends State<QuranKhatmaScreen> {
  String _selectedWirdLabel = '📄 5 صفحات يومياً (معتدل)';
  int _dailyPages = 5;
  String _difficultyLevel = 'متوسط ومستقر 🟡';
  int _currentExactPage = 1;
  int _currentStreak = 3;

  var _khatmasList = [];
  String _activeKhatmaName = 'الختمة العامة';

  final _wirdOptions = [
    {
      'label': '📄 صفحتان يومياً (مريح جداً)',
      'pages': 2,
      'days': 300,
      'level': 'خفيف وسهل 🟢',
    },
    {
      'label': '📄 5 صفحات يومياً (معتدل)',
      'pages': 5,
      'days': 120,
      'level': 'متوسط ومستقر 🟡',
    },
    {
      'label': '📄 10 صفحات يومياً (نصف حزب)',
      'pages': 10,
      'days': 60,
      'level': 'نشط ومستمر 🟡',
    },
    {
      'label': '📖 نصف جزء يومياً (10 صفحات)',
      'pages': 10,
      'days': 60,
      'level': 'نشط ومستمر 🟡',
    },
    {
      'label': '📖 جزء كامل يومياً (ختمة شهر)',
      'pages': 20,
      'days': 30,
      'level': 'تحدي وقوة 🔴',
    },
    {
      'label': '📌 ربع حزب يومياً (2.5 صفحة)',
      'pages': 2,
      'days': 240,
      'level': 'خفيف وسهل 🟢',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadKhatmaData();
  }

  Future<void> _loadKhatmaData() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? multiJson = prefs.getString('saved_multi_khatmas');
    if (multiJson != null) {
      var decoded = json.decode(multiJson);
      if (decoded is List) {
        _khatmasList = decoded;
      }
    } 
    
    if (_khatmasList.isEmpty) {
      _khatmasList = [
        {'name': 'الختمة العامة', 'page': 1, 'wird': '📄 5 صفحات يومياً (معتدل)', 'pages': 5},
        {'name': 'ختمة الحفظ والمراجعة', 'page': 1, 'wird': '📄 صفحتان يومياً (مريح جداً)', 'pages': 2},
      ];
      _saveMultiKhatmasToPrefs();
    }

    setState(() {
      _activeKhatmaName = prefs.getString('active_khatma_name') ?? _khatmasList[0]['name'];
      
      var active = _khatmasList.firstWhere(
        (k) => k['name'] == _activeKhatmaName,
        orElse: () => _khatmasList[0],
      );
      _currentExactPage = active['page'] ?? 1;
      _selectedWirdLabel = active['wird'] ?? '📄 5 صفحات يومياً (معتدل)';
      _dailyPages = active['pages'] ?? 5;
      
      _ensureWirdExistsInOptions(_selectedWirdLabel, _dailyPages, _difficultyLevel);
      
      _currentStreak = prefs.getInt('khatma_streak') ?? 3;
      _difficultyLevel = prefs.getString('khatma_difficulty') ?? 'متوسط ومستقر 🟡';
    });
  }

  void _ensureWirdExistsInOptions(String label, int pages, String level) {
    bool exists = _wirdOptions.any((element) => element['label'] == label);
    if (!exists) {
      _wirdOptions.add({
        'label': label,
        'pages': pages,
        'days': (604 / pages).ceil(),
        'level': level,
      });
    }
  }

  Future<void> _saveMultiKhatmasToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_multi_khatmas', json.encode(_khatmasList));
    await prefs.setString('active_khatma_name', _activeKhatmaName);
  }

  Future<void> _saveKhatmaSettings(int pages, int days, String label, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('khatma_selected_label', label);
    await prefs.setString('khatma_difficulty', level);

    _ensureWirdExistsInOptions(label, pages, level);

    setState(() {
      _dailyPages = pages;
      _selectedWirdLabel = label;
      _difficultyLevel = level;

      for (var k in _khatmasList) {
        if (k['name'] == _activeKhatmaName) {
          k['wird'] = label;
          k['pages'] = pages;
        }
      }
    });

    _saveMultiKhatmasToPrefs();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ تم تحديث ورد الختمة ($_activeKhatmaName): $label'), backgroundColor: Colors.teal),
      );
    }
  }

  // ✨ دالة إعادة تعيين الختمة النشطة إلى الصفحة الأولى مع رسالة تأكيد
  void _resetActiveKhatma() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: Text('🔄 إعادة تعيين "$_activeKhatmaName"', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من إعادة تعيين هذه الختمة والبدء من الصفحة الأولى (1) من جديد؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _currentExactPage = 1;
                for (var k in _khatmasList) {
                  if (k['name'] == _activeKhatmaName) {
                    k['page'] = 1;
                  }
                }
              });
              _saveMultiKhatmasToPrefs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🔄 تم إعادة تعيين الختمة "$_activeKhatmaName" بنجاح'), backgroundColor: Colors.teal),
              );
            },
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  void _showPagesDropdownDialog(String presetTitle, Color color, String defaultLevel) {
    int tempSelectedPages = _dailyPages;
    List<int> availablePages = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30];
    if (!availablePages.contains(tempSelectedPages)) {
      availablePages.add(tempSelectedPages);
      availablePages.sort();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: Text(presetTitle, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر عدد صفحات الورد اليومي:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: tempSelectedPages,
                    dropdownColor: const Color(0xFF1F2937),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: Icon(Icons.arrow_drop_down, color: color),
                    isExpanded: true,
                    items: availablePages.map((int pageCount) {
                      return DropdownMenuItem<int>(
                        value: pageCount,
                        child: Text(
                          '$pageCount صفحات يومياً',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newPages) {
                      if (newPages != null) {
                        setDialogState(() {
                          tempSelectedPages = newPages;
                        });
                      }
                    },
                  ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(context);
                int estimatedDays = (604 / tempSelectedPages).ceil();
                _saveKhatmaSettings(
                  tempSelectedPages,
                  estimatedDays,
                  '📄 $tempSelectedPages صفحات يومياً ($presetTitle)',
                  defaultLevel,
                );
              },
              child: const Text('تطبيق الورد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthsCalculatorDialog() {
    int selectedMonths = 4;
    int remainingPages = 604 - _currentExactPage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int totalDays = selectedMonths * 30;
          int calculatedPages = (remainingPages / totalDays).ceil();
          if (calculatedPages < 1) calculatedPages = 1;

          return AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Row(
              children: [
                Icon(Icons.date_range, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text('📅 حاسبة الختمة بالأسهر', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر المدة الزمنية المطلوبة لختم القرآن:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedMonths,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                      isExpanded: true,
                      items: [1, 2, 3, 4, 6, 12].map((int months) {
                        return DropdownMenuItem<int>(
                          value: months,
                          child: Text(
                            months == 12 ? 'سنة كاملة (12 شهر)' : '$months أشهر',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newMonths) {
                        if (newMonths != null) {
                          setDialogState(() {
                            selectedMonths = newMonths;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 الورد المحسوب: $calculatedPages صفحات يومياً', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('⏱️ المدة الإجمالية: تقريباً $totalDays يوماً', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {
                  Navigator.pop(context);
                  _saveKhatmaSettings(
                    calculatedPages,
                    totalDays,
                    '📅 ختمة $selectedMonths أشهر ($calculatedPages صفحة/يوم)',
                    selectedMonths <= 2 ? 'نشط ومستمر 🟡' : 'خفيف وسهل 🟢',
                  );
                },
                child: const Text('اعتماد الخطة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddKhatmaDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('➕ إضافة ختمة جديدة', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'مثال: ختمة رمضانية، ختمة البقرة...',
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
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _khatmasList.add({
                    'name': nameController.text.trim(),
                    'page': 1,
                    'wird': '📄 5 صفحات يومياً (معتدل)',
                    'pages': 5,
                  });
                  _activeKhatmaName = nameController.text.trim();
                  _currentExactPage = 1;
                  _dailyPages = 5;
                  _selectedWirdLabel = '📄 5 صفحات يومياً (معتدل)';
                });
                _saveMultiKhatmasToPrefs();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✨ تم إنشاء الختمة "${nameController.text}" بنجاح'), backgroundColor: Colors.teal),
                );
              }
            },
            child: const Text('إضافة وتفعيل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progressPercent = (_currentExactPage / 604).clamp(0.0, 1.0);
    int remainingPages = 604 - _currentExactPage;
    int estimatedFinishDays = (remainingPages / _dailyPages).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('📖 مركز الختمة والورد اليومي الذكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // شريط إدارة الختمات المتعددة مع زر إعادة التعيين (Reset)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmarks, color: Colors.tealAccent, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الختمة النشطة حالياً:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(_activeKhatmaName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // زر إعادة التعيين للختمة الحالية
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.amberAccent),
                      tooltip: 'إعادة تعيين الختمة (الرجوع للبداية)',
                      onPressed: _resetActiveKhatma,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.tealAccent),
                      tooltip: 'تبديل الختمة',
                      color: const Color(0xFF1F2937),
                      onSelected: (String name) {
                        setState(() {
                          _activeKhatmaName = name;
                          var selected = _khatmasList.firstWhere((k) => k['name'] == name);
                          _currentExactPage = selected['page'] ?? 1;
                          _selectedWirdLabel = selected['wird'] ?? '📄 5 صفحات يومياً (معتدل)';
                          _dailyPages = selected['pages'] ?? 5;
                          
                          _ensureWirdExistsInOptions(_selectedWirdLabel, _dailyPages, _difficultyLevel);
                        });
                        _saveMultiKhatmasToPrefs();
                      },
                      itemBuilder: (context) {
                        return _khatmasList.map<PopupMenuEntry<String>>((khatma) {
                          return PopupMenuItem<String>(
                            value: khatma['name'],
                            child: Text(khatma['name'], style: const TextStyle(color: Colors.white)),
                          );
                        }).toList();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                      tooltip: 'إضافة ختمة جديدة',
                      onPressed: _showAddKhatmaDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // بطاقة الملخص
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🌟 متابعة: $_activeKhatmaName', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(20)),
                      child: Text('🔥 الاستمرارية: $_currentStreak أيام', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'الصفحة الحالية: $_currentExactPage من 604',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  'متبقي على ختم المصحف: $remainingPages صفحة تقريباً',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // قوالب الختمات السريعة
          const Text('⚡ قوالب الختمات السريعة (اضغط للتخصيص)', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPresetButton(
                  '⚡ ختمة شهر',
                  'تغيير الصفحات',
                  Colors.amberAccent,
                  () => _showPagesDropdownDialog('ختمة شهر', Colors.amberAccent, 'تحدي وقوة 🔴'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  '📅 ختمة الأشهر',
                  'تحديد المدة الزمنية',
                  Colors.tealAccent,
                  () => _showMonthsCalculatorDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  '🧠 ورد التدبر',
                  'تغيير الصفحات',
                  Colors.greenAccent,
                  () => _showPagesDropdownDialog('ورد التدبر', Colors.greenAccent, 'خفيف وسهل 🟢'),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 35),

          // القائمة المنسدلة للورد اليومي الأساسية
          const Text('🎯 تخصيص الورد اليومي بدقة', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('اختر حجم وردك اليومي من القائمة المنسدلة أدناه:', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWirdLabel,
                dropdownColor: const Color(0xFF1F2937),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.amberAccent),
                isExpanded: true,
                items: _wirdOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['label'] as String,
                    child: Text(
                      option['label'] as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    final selectedObj = _wirdOptions.firstWhere((element) => element['label'] == newValue);
                    _saveKhatmaSettings(
                      selectedObj['pages'] as int,
                      selectedObj['days'] as int,
                      selectedObj['label'] as String,
                      selectedObj['level'] as String,
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // الحاسبة التلقائية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 تقرير الورد والوقت المتوقع:', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildInfoRow('📄 مقدار الورد:', '$_dailyPages صفحات يومياً'),
                const Divider(color: Colors.white12, height: 16),
                _buildInfoRow('⏱️ الوقت المتوقع للقراءة:', _getEstimatedTimeText(_dailyPages)),
                const Divider(color: Colors.white12, height: 16),
                _buildInfoRow('⚡ مؤشر الشدة:', _difficultyLevel),
                const Divider(color: Colors.white12, height: 16),
                _buildInfoRow('📅 المدة المتبقية للختمة:', '$estimatedFinishDays يوماً فقط'),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildPresetButton(String title, String subtitle, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ],
      ),
    );
  }

  String _getEstimatedTimeText(int pages) {
    if (pages <= 2) return '3 دقائق تقريباً 🟢';
    if (pages <= 5) return '7-10 دقائق 🟢';
    if (pages <= 10) return '15 دقيقة 🟡';
    return '30 دقيقة 🔴';
  }
}