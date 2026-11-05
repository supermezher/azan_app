import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerSettingsDialog extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final VoidCallback onSettingsChanged;

  const PrayerSettingsDialog({
    super.key,
    required this.currentLat,
    required this.currentLng,
    required this.onSettingsChanged,
  });

  @override
  State<PrayerSettingsDialog> createState() => _PrayerSettingsDialogState();
}

class _PrayerSettingsDialogState extends State<PrayerSettingsDialog> {
  String _selectedMuadhin = 'أذان الحرم المكي';
  bool _autoSilentEnabled = false;
  
  int _calculationMethod = 3; // 3 = رابطة العالم الإسلامي

  int _fajrAdjustment = 0;
  int _dhuhrAdjustment = 0;
  int _asrAdjustment = 0;
  int _maghribAdjustment = 0;
  int _ishaAdjustment = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMuadhin = prefs.getString('selected_muadhin') ?? 'أذان الحرم المكي';
      _autoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
      _calculationMethod = prefs.getInt('calculation_method') ?? 3;
      
      _fajrAdjustment = prefs.getInt('fajr_adj') ?? 0;
      _dhuhrAdjustment = prefs.getInt('dhuhr_adj') ?? 0;
      _asrAdjustment = prefs.getInt('asr_adj') ?? 0;
      _maghribAdjustment = prefs.getInt('maghrib_adj') ?? 0;
      _ishaAdjustment = prefs.getInt('isha_adj') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_muadhin', _selectedMuadhin);
    await prefs.setBool('auto_silent_enabled', _autoSilentEnabled);
    await prefs.setInt('calculation_method', _calculationMethod);
    
    await prefs.setInt('fajr_adj', _fajrAdjustment);
    await prefs.setInt('dhuhr_adj', _dhuhrAdjustment);
    await prefs.setInt('asr_adj', _asrAdjustment);
    await prefs.setInt('maghrib_adj', _maghribAdjustment);
    await prefs.setInt('isha_adj', _ishaAdjustment);

    widget.onSettingsChanged();
    Navigator.pop(context);
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _selectedMuadhin = 'أذان الحرم المكي';
      _autoSilentEnabled = false;
      _calculationMethod = 3;
      _fajrAdjustment = 0;
      _dhuhrAdjustment = 0;
      _asrAdjustment = 0;
      _maghribAdjustment = 0;
      _ishaAdjustment = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.tealAccent),
          SizedBox(width: 8),
          Text('إعدادات الأذان والصلاة', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // اختيار المؤذن
            const Text('اختر المؤذن المفضّل:', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedMuadhin,
              dropdownColor: const Color(0xFF1F2937),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              items: <String>['أذان الحرم المكي', 'أذان المدينة المنورة', 'أذان القدس', 'أذان مصر'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMuadhin = val!),
            ),
            const SizedBox(height: 16),

            // طريقة الحساب
            const Text('طريقة الحساب (Calculation Method):', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _calculationMethod,
              dropdownColor: const Color(0xFF1F2937),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 3, child: Text('رابطة العالم الإسلامي (MWL)')),
                DropdownMenuItem(value: 13, child: Text('رئاسة الشؤون الدينية التركية (Diyanet)')),
                DropdownMenuItem(value: 2, child: Text('ISNA (أمريكا الشمالية)')),
                DropdownMenuItem(value: 5, child: Text('هيئة المساحة المصرية')),
                DropdownMenuItem(value: 4, child: Text('أم القرى (مكة المكرمة)')),
              ],
              onChanged: (val) => setState(() => _calculationMethod = val!),
            ),
            const SizedBox(height: 16),

            // وضع الصامت التلقائي
            SwitchListTile(
              title: const Text('وضع الصامت التلقائي وقت الصلاة', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: _autoSilentEnabled,
              activeColor: Colors.tealAccent,
              onChanged: (val) => setState(() => _autoSilentEnabled = val),
            ),
            const Divider(color: Colors.grey),

            // التعديل اليدوي الدقيق بالدقائق
            const Text('التعديل اليدوي للأوقات (بالدقائق):', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildAdjustmentRow('الفجر', _fajrAdjustment, (val) => setState(() => _fajrAdjustment = val)),
            _buildAdjustmentRow('الظهر', _dhuhrAdjustment, (val) => setState(() => _dhuhrAdjustment = val)),
            _buildAdjustmentRow('العصر', _asrAdjustment, (val) => setState(() => _asrAdjustment = val)),
            _buildAdjustmentRow('المغرب', _maghribAdjustment, (val) => setState(() => _maghribAdjustment = val)),
            _buildAdjustmentRow('العشاء', _ishaAdjustment, (val) => setState(() => _ishaAdjustment = val)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetToDefaults,
          child: const Text('الافتراضي', style: TextStyle(color: Colors.orangeAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          onPressed: _saveSettings,
          child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildAdjustmentRow(String prayerName, int currentVal, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayerName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.redAccent, size: 16),
                onPressed: () => onChanged(currentVal - 1),
              ),
              Text('$currentVal د', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.tealAccent, size: 16),
                onPressed: () => onChanged(currentVal + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}