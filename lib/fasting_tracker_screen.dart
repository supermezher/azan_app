import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key});

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  final Map<String, String> _fastedType = {};
  final Map<String, String> _fastedNotes = {};
  int _totalQadaTarget = 0;
  int _kffaraTarget = 60;
  bool _isLoading = true;

  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _hijriMonths = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
  ];

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('ar');
    HijriCalendar today = HijriCalendar.now();
    _selectedMonth = today.hMonth;
    _selectedYear = today.hYear;
    _loadFastedData();
  }

  Future<void> _loadFastedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      _totalQadaTarget = prefs.getInt('qada_target') ?? 0;
      _kffaraTarget = prefs.getInt('kffara_target') ?? 60;
      for (var key in keys) {
        if (key.startsWith('fast_type_')) {
          _fastedType[key.replaceFirst('fast_type_', '')] = prefs.getString(key) ?? '';
        } else if (key.startsWith('fast_note_')) {
          _fastedNotes[key.replaceFirst('fast_note_', '')] = prefs.getString(key) ?? '';
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _saveDayData(String dateKey, String type, String note) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (type.isEmpty) {
        _fastedType.remove(dateKey);
        _fastedNotes.remove(dateKey);
        prefs.remove('fast_type_$dateKey');
        prefs.remove('fast_note_$dateKey');
      } else {
        _fastedType[dateKey] = type;
        _fastedNotes[dateKey] = note;
        prefs.setString('fast_type_$dateKey', type);
        prefs.setString('fast_note_$dateKey', note);
      }
    });
  }

  Future<void> _updateQadaTarget(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('qada_target', target);
    setState(() {
      _totalQadaTarget = target;
    });
  }

  Future<void> _updateKffaraTarget(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kffara_target', target);
    setState(() {
      _kffaraTarget = target;
    });
  }

  void _showQadaTargetDialog() {
    TextEditingController controller = TextEditingController(text: _totalQadaTarget > 0 ? _totalQadaTarget.toString() : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('سجل أيام قضاء رمضان ⏳', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('كم يوماً عليك قضاؤه من رمضان الماضي؟', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'مثلاً: 6',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                int val = int.tryParse(controller.text) ?? 0;
                _updateQadaTarget(val);
                Navigator.pop(context);
              },
              child: const Text('حفظ العداد'),
            ),
          ],
        );
      },
    );
  }

  void _showKffaraTargetDialog() {
    TextEditingController controller = TextEditingController(text: _kffaraTarget > 0 ? _kffaraTarget.toString() : '60');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('🟣 هدف الكفارة المغلظة (شهرين)', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('الكفارة المغلظة لصيام شهرين متتابعين هي عادة 60 يوماً.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '60',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
              onPressed: () {
                int val = int.tryParse(controller.text) ?? 60;
                _updateKffaraTarget(val);
                Navigator.pop(context);
              },
              child: const Text('حفظ العداد'),
            ),
          ],
        );
      },
    );
  }

  void _markAyyamAlBeed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int day in [13, 14, 15]) {
        String dateKey = 'fast_${_selectedYear}_${_selectedMonth}_$day';
        _fastedType[dateKey] = 'تطوع';
        prefs.setString('fast_type_$dateKey', 'تطوع');
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ تم تحديد الأيام البيض (13، 14، 15) كصيام تطوع!'), backgroundColor: Colors.teal),
      );
    }
  }

  Color _getFastColor(String type) {
    switch (type) {
      case 'قضاء': return Colors.redAccent.shade700;
      case 'تطوع': return Colors.teal.shade700;
      case 'نذر': return Colors.orange.shade800;
      case 'كفارة': return Colors.purple.shade700;
      default: return const Color(0xFF1F2937);
    }
  }

  void _showFastOptionsDialog(String dateKey, int dayNum) {
    String currentType = _fastedType[dateKey] ?? '';
    TextEditingController noteController = TextEditingController(text: _fastedNotes[dateKey] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          // تم تصحيح الفهرس هنا بنجاح (-1)
          title: Text('تسجيل يوم $dayNum من ${_hijriMonths[_selectedMonth - 1]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حدد نوع الصيام:', style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('قضاء', Colors.redAccent, dateKey, currentType),
                    _buildTypeChip('تطوع', Colors.tealAccent, dateKey, currentType),
                    _buildTypeChip('نذر', Colors.orangeAccent, dateKey, currentType),
                    _buildTypeChip('كفارة', Colors.purpleAccent, dateKey, currentType),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('ملاحظة يومية (اختياري):', style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'مثلاً: صمت اليوم كفارة...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            if (currentType.isNotEmpty)
              TextButton(
                onPressed: () {
                  _saveDayData(dateKey, '', '');
                  Navigator.pop(context);
                },
                child: const Text('إلغاء التحديد', style: TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                _saveDayData(dateKey, currentType.isEmpty ? 'تطوع' : currentType, noteController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeChip(String label, Color color, String dateKey, String currentType) {
    bool isSelected = currentType == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: const Color(0xFF111827),
      onSelected: (selected) {
        if (selected) {
          _saveDayData(dateKey, label, _fastedNotes[dateKey] ?? '');
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');
    HijriCalendar today = HijriCalendar.now();

    int qadaFastedCount = 0;
    int kffaraFastedCount = 0;
    _fastedType.forEach((key, type) {
      if (type == 'قضاء') qadaFastedCount++;
      if (type == 'كفارة') kffaraFastedCount++;
    });

    int remainingQada = _totalQadaTarget - qadaFastedCount;
    if (remainingQada < 0) remainingQada = 0;

    int remainingKffara = _kffaraTarget - kffaraFastedCount;
    if (remainingKffara < 0) remainingKffara = 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('متتبع الصيام الشخصي', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('سجل الصيام العام وطوال العام 🌙', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          'إجمالي الأيام المسجلة: ${_fastedType.length} يوم',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(color: Colors.white30, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _totalQadaTarget > 0
                                      ? (remainingQada == 0 ? '🎉 أتممت قضاء رمضان!' : 'متبقي قضاء: $remainingQada أيام')
                                      : 'هدف قضاء رمضان: غير محدد',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (_totalQadaTarget > 0)
                                  Text('صمت $qadaFastedCount من $_totalQadaTarget يوم', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            InkWell(
                              onTap: _showQadaTargetDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.teal.shade900, borderRadius: BorderRadius.circular(6)),
                                child: const Text('تعديل القضاء', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _kffaraTarget > 0
                                      ? (remainingKffara == 0 ? '🎉 أتممت الكفارة (60 يوم)!' : 'الكفارة المتبقية: $remainingKffara يوم')
                                      : 'الكفارة المغلظة: غير محددة',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text('صمت $kffaraFastedCount من $_kffaraTarget يوم (شهرين)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            InkWell(
                              onTap: _showKffaraTargetDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.purple.shade900, borderRadius: BorderRadius.circular(6)),
                                child: const Text('تعديل الكفارة', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DropdownButton<int>(
                                value: _selectedMonth,
                                dropdownColor: const Color(0xFF1F2937),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                underline: const SizedBox(),
                                items: List.generate(12, (index) {
                                  int monthNum = index + 1;
                                  return DropdownMenuItem<int>(
                                    value: monthNum,
                                    child: Text(_hijriMonths[index]),
                                  );
                                }),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedMonth = val);
                                },
                              ),
                              DropdownButton<int>(
                                value: _selectedYear,
                                dropdownColor: const Color(0xFF1F2937),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                underline: const SizedBox(),
                                items: List.generate(11, (index) {
                                  int yearValue = today.hYear - 5 + index;
                                  return DropdownMenuItem<int>(
                                    value: yearValue,
                                    child: Text('$yearValue هـ'),
                                  );
                                }),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedYear = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _markAyyamAlBeed,
                        icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                        label: const Text('البيض', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: 30,
                      itemBuilder: (context, index) {
                        int dayNum = index + 1;
                        String dateKey = 'fast_${_selectedYear}_${_selectedMonth}_$dayNum';
                        String type = _fastedType[dateKey] ?? '';
                        bool isFasted = type.isNotEmpty;

                        return InkWell(
                          onTap: () => _showFastOptionsDialog(dateKey, dayNum),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFasted ? _getFastColor(type) : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('يوم $dayNum', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  if (isFasted)
                                    Text(type, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}