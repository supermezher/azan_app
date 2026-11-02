import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranAnalyticsScreen extends StatefulWidget {
  const QuranAnalyticsScreen({super.key});

  @override
  State<QuranAnalyticsScreen> createState() => _QuranAnalyticsScreenState();
}

class _QuranAnalyticsScreenState extends State<QuranAnalyticsScreen> {
  int _streak = 0;
  int _currentDay = 1;
  int _exactPage = 1;
  int _totalVersesRead = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streak = prefs.getInt('khatma_streak') ?? 0;
      _currentDay = prefs.getInt('khatma_current_day') ?? 1;
      _exactPage = prefs.getInt('khatma_exact_page') ?? 1;
      _totalVersesRead = prefs.getInt('total_verses_read') ?? (_exactPage * 10); // تقدير تقريبي مبدئي
    });
  }

  @override
  Widget build(BuildContext context) {
    double khatmaProgress = (_exactPage / 604.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('📊 إحصاءات ونشاط الختمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة التهنئة والاستمرارية (Streak Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔥 أيام الاستمرارية (Streak)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        '$_streak أ أيام متتالية',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('استمر في قراءة وردك لتحافظ على السلسلة!', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1F2937),
                    child: Icon(Icons.local_fire_department, color: Colors.amberAccent, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // شبكة الإحصاءات السريعة (Grid Cards)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'يوم الختمة الحالي',
                    value: 'اليوم $_currentDay',
                    icon: Icons.calendar_today,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'الصفحة الحالية',
                    value: '$_exactPage / 604',
                    icon: Icons.menu_book,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'الآيات المقروءة',
                    value: '$_totalVersesRead آية',
                    icon: Icons.format_quote,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'الختمات المكتملة',
                    value: '${(_currentDay ~/ 30)} ختمة',
                    icon: Icons.military_tech,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // بطاقة نسبة إنجاز الختمة الكلية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 نسبة إنجاز الختمة الحالية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: khatmaProgress,
                    backgroundColor: Colors.white12,
                    color: Colors.tealAccent,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('تم إنجاز ${(khatmaProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                      const Text('المتبقي: القرآن الكريم', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // قسم سجل النشاط الأسبوعي (Heatmap Simulation)
            const Text('🗓️ نشاط القراءة خلال الأسبوع الماضي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  bool isActive = index < (_streak % 7 + 1);
                  List<String> days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.teal : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isActive ? Icons.check : Icons.remove,
                          color: isActive ? Colors.tealAccent : Colors.white24,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(days[index], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}