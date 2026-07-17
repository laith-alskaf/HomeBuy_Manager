import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import 'package:homebuy_manager/data/models/shopping_item.dart';
import 'package:homebuy_manager/utils/date_utils.dart';
import '../../../utils/formatters.dart';

class AnalyticsView extends StatefulWidget {
  final List<ShoppingItem> items;
  final Map<String, dynamic> categories;

  const AnalyticsView({
    super.key,
    required this.items,
    required this.categories,
  });

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String _analyticsMode = 'month'; // 'day', 'month', 'range', 'all'
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // إضافة بطاقة المقارنة الذكية هنا
        _buildSmartComparisonCard(),
        const SizedBox(height: 15),
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('day', 'باليوم'),
              _buildFilterChip('month', 'بالشهر'),
              _buildFilterChip('range', 'مخصص'),
              _buildFilterChip('all', 'الكل'),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (_analyticsMode == 'day') _buildDaySelector(),
        if (_analyticsMode == 'month') _buildMonthSelector(),
        if (_analyticsMode == 'range') _buildRangeSelector(),
        if (_analyticsMode == 'all')
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('عرض تحليل شامل لكل المشتريات',
                style: TextStyle(color: AppColors.textLight)),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: _buildFilteredContent(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String mode, String label) {
    bool isSelected = _analyticsMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _analyticsMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDay,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('ar', 'SY'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDay = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              formatDateSimple(_selectedDay),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => setState(() => _selectedMonth =
              DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedMonth,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              locale: const Locale('ar', 'SY'),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme:
                        const ColorScheme.light(primary: AppColors.primary),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(
                  () => _selectedMonth = DateTime(picked.year, picked.month));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${getArabicMonth(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _selectedMonth =
              DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
        ),
      ],
    );
  }

  // ودجت المقارنة الذكية (جديد)
  Widget _buildSmartComparisonCard() {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1);

    // حساب مصاريف الشهر الحالي
    final currentMonthItems = widget.items.where((i) =>
        i.isBought &&
        i.dateBought != null &&
        i.dateBought!.year == now.year &&
        i.dateBought!.month == now.month);

    double currentSyp = 0;
    double currentUsd = 0;

    for (var item in currentMonthItems) {
      double total = item.price * item.quantity;
      currentSyp += total;

      double rate = item.exchangeRate ?? 0.0;
      if (rate > 0) {
        currentUsd += total / rate;
      }
    }

    // حساب مصاريف الشهر الماضي
    final lastMonthItems = widget.items.where((i) =>
        i.isBought &&
        i.dateBought != null &&
        i.dateBought!.year == lastMonthDate.year &&
        i.dateBought!.month == lastMonthDate.month);

    double lastSyp = 0;
    double lastUsd = 0;

    for (var item in lastMonthItems) {
      double total = item.price * item.quantity;
      lastSyp += total;

      double rate = item.exchangeRate ?? 0.0;
      if (rate > 0) {
        lastUsd += total / rate;
      }
    }

    if (currentSyp == 0 && lastSyp == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436), // لون داكن فخم
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('نظرة مالية ذكية',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'أنت صرفت ${formatCurrency(currentSyp)} ل.س هذا الشهر، وهي تعادل ${currentUsd.toStringAsFixed(1)}\$، بينما الشهر الماضي صرفت ${formatCurrency(lastSyp)} ل.س ولكنها كانت تعادل ${lastUsd.toStringAsFixed(1)}\$.',
            style: const TextStyle(
                color: Colors.white70, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDateRange = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              _selectedDateRange == null
                  ? 'اضغط لاختيار الفترة'
                  : '${formatDateSimple(_selectedDateRange!.start)} - ${formatDateSimple(_selectedDateRange!.end)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredContent() {
    final boughtItems =
        widget.items.where((i) => i.isBought && i.dateBought != null).toList();
    List<ShoppingItem> filteredItems = [];

    if (_analyticsMode == 'all') {
      filteredItems = boughtItems;
    } else if (_analyticsMode == 'day') {
      filteredItems = boughtItems
          .where((i) =>
              i.dateBought!.year == _selectedDay.year &&
              i.dateBought!.month == _selectedDay.month &&
              i.dateBought!.day == _selectedDay.day)
          .toList();
    } else if (_analyticsMode == 'month') {
      filteredItems = boughtItems
          .where((i) =>
              i.dateBought!.year == _selectedMonth.year &&
              i.dateBought!.month == _selectedMonth.month)
          .toList();
    } else if (_analyticsMode == 'range' && _selectedDateRange != null) {
      filteredItems = boughtItems
          .where((i) =>
              i.dateBought!.isAfter(_selectedDateRange!.start
                  .subtract(const Duration(days: 1))) &&
              i.dateBought!.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1))))
          .toList();
    } else if (_analyticsMode == 'range' && _selectedDateRange == null) {
      return const Center(
          child: Text('الرجاء اختيار فترة زمنية',
              style: TextStyle(color: Colors.grey)));
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('لا توجد بيانات لهذه الفترة',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return _buildCharts(filteredItems);
  }

  Widget _buildCharts(List<ShoppingItem> filteredItems) {
    double totalPeriodCost =
        filteredItems.fold(0, (sum, i) => sum + (i.price * i.quantity));

    Map<String, double> catCosts = {};
    for (var item in filteredItems) {
      catCosts[item.category] =
          (catCosts[item.category] ?? 0) + (item.price * item.quantity);
    }

    Map<int, double> dailyCosts = {};
    for (var item in filteredItems) {
      int day = item.dateBought!.day;
      dailyCosts[day] = (dailyCosts[day] ?? 0) + (item.price * item.quantity);
    }

    final topSpenders = filteredItems.toList()
      ..sort((a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity));

    // إعداد بيانات الرسم البياني الدائري (Pie Chart)
    List<PieChartSectionData> pieSections = [];
    if (totalPeriodCost > 0) {
      final sortedCats = catCosts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      pieSections = sortedCats.map((entry) {
        final catData =
            widget.categories[entry.key] ?? widget.categories['other'];
        final percentage = entry.value / totalPeriodCost;
        return PieChartSectionData(
          color: catData['color'] as Color,
          value: entry.value,
          title: '${(percentage * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المصروف في الفترة المحددة',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12)),
                    const SizedBox(height: 5),
                    Text('${formatCurrency(totalPeriodCost)} ل.س',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.show_chart,
                      color: Colors.white, size: 30),
                )
              ],
            ),
          ),
          const SizedBox(height: 25),
          if (_analyticsMode != 'all' && _analyticsMode != 'day') ...[
            const Text('النشاط اليومي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: dailyCosts.isEmpty
                  ? const Center(child: Text('لا توجد بيانات يومية'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: dailyCosts.values.reduce(max) * 1.2,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                formatCurrency(rod.toY),
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(value.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ),
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: dailyCosts.entries.map((e) {
                          return BarChartGroupData(x: e.key, barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: AppColors.primary,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: dailyCosts.values.reduce(max) * 1.2,
                                  color: Colors.grey.shade100),
                            )
                          ]);
                        }).toList()
                          ..sort((a, b) => a.x.compareTo(b.x)),
                      ),
                    ),
            ),
            const SizedBox(height: 25),
          ],
          const Text('توزيع المصاريف حسب الفئة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (pieSections.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: catCosts.entries.map((entry) {
                final catData =
                    widget.categories[entry.key] ?? widget.categories['other'];
                final percentage =
                    entry.value / (totalPeriodCost > 0 ? totalPeriodCost : 1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (catData['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(catData['icon'],
                            size: 16, color: catData['color']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(catData['label'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${(percentage * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: catData['color'],
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(formatCurrency(entry.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 25),
          const Text('أعلى المشتريات تكلفة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...topSpenders.take(3).map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.trending_up,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${formatCurrency(item.price * item.quantity)} ل.س',
                      style: const TextStyle(color: AppColors.textLight)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
