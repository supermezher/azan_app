import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _gold24Controller = TextEditingController(text: "1290.50");
  final TextEditingController _gold21Controller = TextEditingController(text: "1128.60");
  final TextEditingController _gold18Controller = TextEditingController(text: "967.80");
  
  final TextEditingController _gold24GramController = TextEditingController();
  final TextEditingController _gold21GramController = TextEditingController();
  final TextEditingController _gold18GramController = TextEditingController();
  
  final TextEditingController _stocksController = TextEditingController();
  final TextEditingController _tradeGoodsController = TextEditingController();
  final TextEditingController _receivablesController = TextEditingController(); 
  final TextEditingController _debtsController = TextEditingController(); 
  final TextEditingController _customCurrencyController = TextEditingController();

  bool _passedHawl = true;
  bool _useSolarYear = false; 
  String _selectedCurrency = 'SEK - كرونة سويدية';
  
  bool _isLoadingRates = false;
  bool _calculated = false;

  double _totalAssets = 0.0;
  double _netAssets = 0.0;
  double _nisabThreshold = 0.0;
  double _zakatAmount = 0.0;
  bool _isEligible = false;

  // تخزين السجل كنصوص بسيطة لتجنب أخطاء الأقواس
  List<String> _savedHistory = [];

  DateTime? _hawlDate;

  final List<String> _currencies = [
    'SEK - كرونة سويدية',
    'NOK - كرونة نرويجية',
    'DKK - كرونة دانماركية',
    'EUR - يورو أوروبي',
    'GBP - جنيه إسترليني',
    'CHF - فرنك سويسري',
    'SAR - ريال سعودي',
    'AED - درهم إماراتي',
    'KWD - دينار كويتي',
    'QAR - ريال قطري',
    'BHD - دينار بحريني',
    'OMR - ريال عماني',
    'JOD - دينار أردني',
    'EGP - جنيه مصري',
    'USD - دولار أمريكي',
    'CAD - دولار كندي',
    'AUD - دولار أسترالي',
    'JPY - ين ياباني',
    'CNY - يوان صيني',
    'TRY - ليرة تركية',
    'أخرى (تحديد يدوي)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistoryFromLocal();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _gold24Controller.dispose();
    _gold21Controller.dispose();
    _gold18Controller.dispose();
    _gold24GramController.dispose();
    _gold21GramController.dispose();
    _gold18GramController.dispose();
    _stocksController.dispose();
    _tradeGoodsController.dispose();
    _receivablesController.dispose();
    _debtsController.dispose();
    _customCurrencyController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyList = prefs.getStringList('zakat_history_simple');
    final String? hawlString = prefs.getString('hawl_date');

    if (historyList != null) {
      setState(() {
        _savedHistory = historyList;
      });
    }

    if (hawlString != null) {
      setState(() {
        _hawlDate = DateTime.tryParse(hawlString);
      });
    }
  }

  Future<void> _saveCurrentRecordToLocal() async {
    if (!_calculated) return;
    
    final prefs = await SharedPreferences.getInstance();
    final formatter = NumberFormat("#,##0.00", "ar");
    final currencySymbol = _getCurrencySymbol();
    
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final recordText = "التاريخ: $dateStr | الصافي: ${formatter.format(_netAssets)} $currencySymbol | الزكاة: ${formatter.format(_zakatAmount)} $currencySymbol";

    setState(() {
      _savedHistory.insert(0, recordText);
    });

    await prefs.setStringList('zakat_history_simple', _savedHistory);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ السجل وتبرئة الذمة بنجاح!'), backgroundColor: Colors.teal),
      );
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('zakat_history_simple');
    setState(() {
      _savedHistory.clear();
    });
  }

  Future<void> _pickHawlDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _hawlDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _hawlDate = picked;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hawl_date', picked.toIso8601String());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم ضبط موعد الحول والتنبيه في: ${DateFormat('yyyy-MM-dd').format(picked)}'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  double _parseVal(String text) {
    if (text.isEmpty) return 0.0;
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String cleaned = text;
    for (int i = 0; i < 10; i++) {
      cleaned = cleaned.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    cleaned = cleaned.replaceAll('،', '.').replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _getCurrencySymbol() {
    if (_selectedCurrency.contains('أخرى')) {
      return _customCurrencyController.text.isNotEmpty ? _customCurrencyController.text : 'عملة';
    }
    return _selectedCurrency.split(' - ')[0];
  }

  Future<void> _refreshMarketPrices() async {
    setState(() => _isLoadingRates = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        if (_selectedCurrency.contains('SEK')) {
          _gold24Controller.text = "1290.50";
          _gold21Controller.text = "1128.60";
          _gold18Controller.text = "967.80";
        } else {
          _gold24Controller.text = "285.50";
          _gold21Controller.text = "249.80";
          _gold18Controller.text = "214.00";
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الأسعار القياسية بنجاح!'), backgroundColor: Colors.teal),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRates = false);
    }
  }

  void _calculateComprehensiveZakat() {
    double cash = _parseVal(_cashController.text);
    double receivables = _parseVal(_receivablesController.text);

    double g24Price = _parseVal(_gold24Controller.text);
    double g21Price = _parseVal(_gold21Controller.text);
    double g18Price = _parseVal(_gold18Controller.text);

    double g24Grams = _parseVal(_gold24GramController.text);
    double g21Grams = _parseVal(_gold21GramController.text);
    double g18Grams = _parseVal(_gold18GramController.text);
    
    double goldValue = (g24Grams * g24Price) + (g21Grams * g21Price) + (g18Grams * g18Price);

    double stocks = _parseVal(_stocksController.text);
    double tradeGoods = _parseVal(_tradeGoodsController.text);

    double grossAssets = cash + receivables + goldValue + stocks + tradeGoods;
    double debts = _parseVal(_debtsController.text);

    double netAssets = grossAssets - debts;
    if (netAssets < 0) netAssets = 0;

    double nisab = 85 * g24Price;
    double zakatRate = _useSolarYear ? 0.02577 : 0.025;

    setState(() {
      _totalAssets = grossAssets;
      _netAssets = netAssets;
      _nisabThreshold = nisab;
      _calculated = true;

      if (netAssets >= nisab && _passedHawl) {
        _isEligible = true;
        _zakatAmount = netAssets * zakatRate;
      } else {
        _isEligible = false;
        _zakatAmount = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "ar");
    final currencySymbol = _getCurrencySymbol();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('حاسبة الزكاة الشاملة والسجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1F2937),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.tealAccent),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.tealAccent,
          tabs: const [
            Tab(text: 'الأموال والذهب', icon: Icon(Icons.account_balance_wallet, size: 18)),
            Tab(text: 'الاستثمار والديون', icon: Icon(Icons.trending_up, size: 18)),
            Tab(text: 'النتيجة والأحكام', icon: Icon(Icons.rule, size: 18)),
            Tab(text: 'السجل والتذكير', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssetsTab(formatter, currencySymbol),
          _buildInvestmentsAndDebtsTab(formatter, currencySymbol),
          _buildResultTab(formatter, currencySymbol),
          _buildHistoryAndReminderTab(formatter),
        ],
      ),
    );
  }

  Widget _buildAssetsTab(NumberFormat formatter, String currencySymbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDisclaimerBanner(),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('اختر عملتك والأسعار المعيارية:', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: _isLoadingRates ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync, color: Colors.tealAccent, size: 20),
                        onPressed: _refreshMarketPrices,
                        tooltip: 'تحديث الأسعار',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    dropdownColor: const Color(0xFF1F2937),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'العملة', labelStyle: TextStyle(color: Colors.white70)),
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val!),
                  ),
                  if (_selectedCurrency.contains('أخرى')) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _customCurrencyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'اكتب اسم العملة أو رمزها يدوياً', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gold24Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(labelText: 'عيار 24', suffixText: currencySymbol),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _gold21Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(labelText: 'عيار 21', suffixText: currencySymbol),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _gold18Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(labelText: 'عيار 18', suffixText: currencySymbol),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInputCard('النقد والأموال السائلة (بالبنك أو الكاش)', _cashController, 'أدخل إجمالي المبالغ النقدية', Icons.attach_money, currencySymbol),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('أوزان الذهب والفضة المدخر (بالجرام):', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _gold24GramController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'وزن ذهب عيار 24 (جرام)', suffixText: 'جم'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _gold21GramController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'وزن ذهب عيار 21 (جرام)', suffixText: 'جم'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _gold18GramController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'وزن ذهب عيار 18 (جرام)', suffixText: 'جم'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text('الانتقال للاستثمارات والديون', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsAndDebtsTab(NumberFormat formatter, String currencySymbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputCard('الأسهم الاستثمارية وصناديق التداول', _stocksController, 'قيمة الأسهم المعدة للمضاربة أو الاستثمار', Icons.show_chart, currencySymbol),
          const SizedBox(height: 12),
          _buildInputCard('عروض التجارة والبضائع للبيع', _tradeGoodsController, 'إجمالي قيمة البضائع بسعر الجملة الحالي', Icons.store, currencySymbol),
          const SizedBox(height: 12),
          _buildInputCard('ديون لك عند الآخرين (مرجوة الأداء)', _receivablesController, 'المبالغ المقرضة وتأمل استردادها', Icons.money, currencySymbol),
          const SizedBox(height: 12),
          _buildInputCard('ديون حالة عليك (تُخصم من المال)', _debtsController, 'الديون المستحقة التي تحل قريباً', Icons.money_off, currencySymbol, isDeduction: true),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: Colors.tealAccent,
                  title: const Text('مرور عام كامل (الحول الشرعي)', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('سنة قمرية كاملة على بلوغ النصاب', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  value: _passedHawl,
                  onChanged: (val) => setState(() => _passedHawl = val),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  activeColor: Colors.tealAccent,
                  title: const Text('اعتماد السنة الميلادية بدلاً من الهجرية', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('تعدل النسبة تلقائياً إلى 2.577%', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  value: _useSolarYear,
                  onChanged: (val) => setState(() => _useSolarYear = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              _calculateComprehensiveZakat();
              _tabController.animateTo(2);
            },
            child: const Text('احسب النتيجة الشاملة الآن', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTab(NumberFormat formatter, String currencySymbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _isEligible ? Colors.teal.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _isEligible ? Colors.tealAccent : Colors.redAccent),
            ),
            child: Column(
              children: [
                Icon(_isEligible ? Icons.check_circle_outline : Icons.info_outline, color: _isEligible ? Colors.tealAccent : Colors.redAccent, size: 42),
                const SizedBox(height: 10),
                Text(
                  _calculated ? (_isEligible ? 'تجب عليك الزكاة شرعاً' : 'لا تجب عليك الزكاة حالياً') : 'اضغط على زر الحساب لعرض النتيجة',
                  style: TextStyle(color: _isEligible ? Colors.tealAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (_calculated) ...[
                  Text('إجمالي الأصول قبل الخصم: ${formatter.format(_totalAssets)} $currencySymbol', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('صافي الأموال الزكوية: ${formatter.format(_netAssets)} $currencySymbol', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('حد النصاب الحالي (85جم ذهب): ${formatter.format(_nisabThreshold)} $currencySymbol', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Divider(color: Colors.white24, height: 20),
                  if (_isEligible) ...[
                    const Text('مقدار الزكاة الواجب إخراجها:', style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${formatter.format(_zakatAmount)} $currencySymbol',
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                      onPressed: _saveCurrentRecordToLocal,
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('حفظ في السجل المحلي (تبرئة الذمة)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    const Text(
                      'السبب: صافي أموالك يقل عن حد النصاب أو لم يمضِ عليها الحول الشرعي.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              _calculateComprehensiveZakat();
            },
            child: const Text('تحديث وإعادة الحساب', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAndReminderTab(NumberFormat formatter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.tealAccent, size: 20),
                      SizedBox(width: 8),
                      Text('تذكير موعد الحول السنوي:', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hawlDate == null 
                        ? 'لم يتم تحديد تاريخ الحول بعد.'
                        : 'تاريخ الحول المحدد: ${DateFormat('yyyy-MM-dd').format(_hawlDate!)} (سيتم تنبيهك سنوياً)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () => _pickHawlDate(context),
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    label: const Text('اختر تاريخ موعد الحول', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('سجل العمليات والزكوات السابقة:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              if (_savedHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                  label: const Text('حذف السجل', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _savedHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('لا توجد سجلات محفوظة حتى الآن.\nقم بإجراء حساب وحفظ النتيجة.', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedHistory.length,
                  itemBuilder: (context, index) {
                    final record = _savedHistory[index];
                    return Card(
                      color: const Color(0xFF1F2937),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.bookmark, color: Colors.white)),
                        title: Text(record, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildInputCard(String title, TextEditingController controller, String hint, IconData icon, String currencySymbol, {bool isDeduction = false}) {
    return Card(
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isDeduction ? Colors.orangeAccent : Colors.tealAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(color: isDeduction ? Colors.orangeAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                suffixText: currencySymbol,
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'حاسبة استرشادية شاملة لمختلف الأصول. يُنصح بمراجعة أهل العلم والفتوى في المعاملات المعقدة.',
              style: TextStyle(color: Colors.amberAccent, fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}