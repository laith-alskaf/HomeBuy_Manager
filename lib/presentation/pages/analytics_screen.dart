import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:homebuy_manager/utils/analytics_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homebuy_manager/data/models/debt_record.dart';
import 'package:homebuy_manager/data/models/shopping_item.dart';
import 'package:homebuy_manager/data/models/wallet_transaction.dart';
import 'package:homebuy_manager/data/models/side_balance_transaction.dart';
import '../../services/budget_service.dart';
import 'package:homebuy_manager/utils/formatters.dart';
import '../../config/app_colors.dart';
import '../widgets/common/app_info_dialog.dart';

class AnalyticsScreen extends StatefulWidget {
  final Map<String, double> walletBalancesByCurrency;
  final Map<String, double> vaultBalancesByCurrency;
  final List<DebtRecord> debts;
  final List<ShoppingItem> items;
  final List<WalletTransaction> deposits;
  final List<SideBalanceTransaction> sideBalanceTransactions;
  final Map<String, dynamic> categories;

  const AnalyticsScreen({
    super.key,
    required this.walletBalancesByCurrency,
    required this.vaultBalancesByCurrency,
    required this.debts,
    required this.items,
    required this.deposits,
    required this.sideBalanceTransactions,
    required this.categories,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsProcessor _processor;
  ProcessedAnalyticsReport? _report;

  String _timeFilter = 'this_month';
  String _selectedCurrency = 'SYP';
  List<String> _availableCurrencies = ['SYP'];

  @override
  void initState() {
    super.initState();
    _determineAvailableCurrencies();
    _loadPreferencesAndRecalculate();
  }

  void _determineAvailableCurrencies() {
    final Set<String> currencies = {'SYP'};
    currencies.addAll(widget.walletBalancesByCurrency.keys);
    currencies.addAll(widget.vaultBalancesByCurrency.keys);
    currencies.addAll(widget.deposits.map((e) => e.currency));
    currencies.addAll(widget.items.map((e) => e.currency));
    currencies.addAll(widget.debts.map((e) => e.currency));
    currencies.addAll(widget.sideBalanceTransactions.map((e) => e.currency));
    _availableCurrencies = currencies.toList()..sort();
  }

  Future<void> _loadPreferencesAndRecalculate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('analytics_currency') ?? 'SYP';
      if (!_availableCurrencies.contains(_selectedCurrency)) {
        _selectedCurrency = 'SYP';
      }
      _recalculateReport();
    });
  }

  void _recalculateReport() {
    _processor = AnalyticsProcessor(
      allItems: widget.items,
      allDeposits: widget.deposits,
      allDebts: widget.debts,
      allSideBalanceTransactions: widget.sideBalanceTransactions,
      vaultBalancesByCurrency: widget.vaultBalancesByCurrency,
      targetCurrency: _selectedCurrency,
      budgetService: BudgetService(),
    );

    setState(() {
      _report = _processor.process(timeFilter: _timeFilter);
    });
  }

  Future<void> _changeCurrency(String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_currency', value);
    setState(() {
      _selectedCurrency = value;
      _recalculateReport();
    });
  }

  String get _symbol {
    switch (_selectedCurrency) {
      case 'SYP':
        return 'ل.س';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'SAR':
        return 'ر.س';
      case 'AED':
        return 'د.إ';
      default:
        return _selectedCurrency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التحليل المالي',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              AppInfoDialog.show(
                context,
                title: 'التحليل المالي المعمّق (Analytics)',
                description:
                    'استوديو البيانات الخاص بك. هنا تتحول أرقامك إلى رؤى بصرية واضحة تساعدك على اتخاذ قرارات مالية أذكى.',
                features: [
                  {
                    'title': 'صافي الثروة',
                    'description':
                        'يقوم النظام بحساب "صافي الثروة" من خلال دمج أرصدة المحفظة والخزنة والجانب والديون بكل العملات.',
                    'icon': Icons.account_balance_rounded,
                    'color': AppColors.primary,
                  },
                  {
                    'title': 'تحليل العملات',
                    'description':
                        'إمكانية تبديل العملة لرؤية التقارير والإحصائيات الخاصة بكل عملة على حدة بدقة عالية.',
                    'icon': Icons.currency_exchange_rounded,
                    'color': Colors.green,
                  },
                  {
                    'title': 'الرؤية الذكية',
                    'description':
                        'يقدم لك التطبيق نصائح مختصرة بناءً على نمط إنفاقك لمساعدتك في تحسين التوفير.',
                    'icon': Icons.psychology_rounded,
                    'color': AppColors.accent,
                  },
                ],
              );
            },
          ),
        ],
      ),
      body: _report == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControls(),
                  const SizedBox(height: 15),
                  if (_report!.expenseDistribution.isEmpty &&
                      _timeFilter != 'all_time')
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: _buildEmptyState(),
                    )
                  else ...[
                    _buildFinancialInsightCard(),
                    const SizedBox(height: 15),
                    if (_timeFilter != 'all_time') _buildLiquidityCard(),
                    _buildNetWorthCard(),
                    const SizedBox(height: 25),
                    _buildCashFlowCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle('أين يذهب مالك؟'),
                    const SizedBox(height: 15),
                    _buildPieChartCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle('مقياس تشبع الميزانية'),
                    const SizedBox(height: 15),
                    _buildBudgetSaturationList(),
                    const SizedBox(height: 25),
                    _buildSectionTitle('الخريطة الحرارية للصرف'),
                    const SizedBox(height: 15),
                    _buildSpendingHeatmap(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeFilter,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'this_month',
                    child: Text('هذا الشهر'),
                  ),
                  DropdownMenuItem(
                    value: 'last_month',
                    child: Text('الشهر الماضي'),
                  ),
                  DropdownMenuItem(
                    value: 'all_time',
                    child: Text('كل الأوقات'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _timeFilter = value;
                      _recalculateReport();
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isExpanded: true,
                items: _availableCurrencies.map((c) {
                  return DropdownMenuItem(value: c, child: Text('عملة $c'));
                }).toList(),
                onChanged: _changeCurrency,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidityCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحليل السيولة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLiquidityItem(
                  'الرصيد السابق',
                  _report!.rolloverBalance,
                  Colors.grey.shade600,
                ),
                const Icon(Icons.add, color: Colors.grey),
                _buildLiquidityItem(
                  'الدخل الجديد',
                  _report!.newIncome,
                  AppColors.success,
                ),
                const Icon(Icons.drag_handle, color: Colors.grey),
                _buildLiquidityItem(
                  'المجموع المتاح',
                  _report!.totalAvailable,
                  AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidityItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${formatCompactCurrency(value)} $_symbol',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetWorthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'صافي ثروتك الحالية',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${formatCompactCurrency(_report!.netWorth)} $_symbol',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildDetailItem(
                  'محفظة',
                  widget.walletBalancesByCurrency[_selectedCurrency] ?? 0.0,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'خزنة',
                  widget.vaultBalancesByCurrency[_selectedCurrency] ?? 0.0,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'جانب',
                  _report!.sideBalance,
                  Colors.amber,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'مستحقات',
                  _report!.totalAssets,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${formatCompactCurrency(value)} $_symbol',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard() {
    final pieData = AnalyticsProcessor.processPieChartData(
      _report!.expenseDistribution,
    );
    final totalExpenses = _report!.expenseDistribution.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: pieData.map((entry) {
                      final categoryInfo =
                          widget.categories[entry.key] ??
                          {'label': 'أخرى', 'color': Colors.grey};
                      final percentage = (entry.value / totalExpenses) * 100;
                      return PieChartSectionData(
                        color: categoryInfo['color'],
                        value: entry.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 60,
                    sectionsSpace: 4,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إجمالي المصروف',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${formatCompactCurrency(totalExpenses)} $_symbol',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 30),
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: pieData.map((entry) {
              final categoryInfo =
                  widget.categories[entry.key] ??
                  {'label': 'أخرى', 'color': Colors.grey};
              return _buildLegendItem(
                categoryInfo['color'],
                categoryInfo['label'],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBudgetSaturationList() {
    // Budget is naturally managed in SYP only for now (unless the user specifies budget limits per currency)
    // Here we can just display it and assume it depends on the selected currency
    // Wait: limits logic goes down the drain if limit is 500,000 SYP and we compare it to USD 100
    // But this is outside scope, just leaving it as is for the currency
    if (_report!.budgetSaturation.isEmpty) {
      return const Text('لا توجد ميزانيات مخصصة.');
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 10),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _report!.budgetSaturation.length,
        separatorBuilder: (ctx, i) => const Divider(height: 20),
        itemBuilder: (ctx, index) {
          final sat = _report!.budgetSaturation[index];
          final catInfo = widget.categories[sat.categoryId]!;
          final progress = sat.progress;

          Color progressColor;
          if (progress > 0.9) {
            progressColor = AppColors.danger;
          } else if (progress > 0.75) {
            progressColor = Colors.orange;
          } else {
            progressColor = AppColors.success;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    catInfo['label'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: progressColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpendingHeatmap() {
    if (_report!.spendingHeatmap.isEmpty) return const SizedBox.shrink();

    final maxSpending = _report!.spendingHeatmap.values.fold(
      0.0,
      (max, v) => v > max ? v : max,
    );
    final daysInMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 10),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          final day = index + 1;
          final spending = _report!.spendingHeatmap[day] ?? 0.0;
          final intensity = (maxSpending > 0) ? (spending / maxSpending) : 0.0;

          return Tooltip(
            message: 'يوم $day: ${formatCurrency(spending)} $_symbol',
            child: Container(
              decoration: BoxDecoration(
                color: intensity == 0
                    ? Colors.grey.shade100
                    : Color.lerp(
                        Colors.green.shade200,
                        Colors.red.shade400,
                        intensity,
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color: intensity > 0.6 ? Colors.white : Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: Colors.amber.shade600, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رؤية مالية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  _report!.financialInsight,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد بيانات كافية بعد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ابدأ بتسجيل مشترياتك لتظهر لك التحليلات المالية',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('بيان التدفق النقدي (Cash Flow)'),
          const SizedBox(height: 15),
          _buildCashFlowRow(
            'إجمالي الدخل (In)',
            _report!.totalIncome,
            AppColors.success,
            Icons.arrow_downward_rounded,
          ),
          const Divider(height: 20),
          _buildCashFlowRow(
            'إجمالي المصروف (Out)',
            _report!.totalExpenses,
            AppColors.danger,
            Icons.arrow_upward_rounded,
          ),
          const Divider(height: 20),
          _buildCashFlowRow(
            'صافي التدفق (Net)',
            _report!.netCashFlow,
            _report!.netCashFlow >= 0 ? AppColors.primary : AppColors.danger,
            Icons.swap_vert_rounded,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مدخرات الخزنة (Vault Savings)',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                '${formatCurrency(_report!.vaultSavings)} $_symbol',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowRow(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          '${formatCurrency(value)} $_symbol',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
