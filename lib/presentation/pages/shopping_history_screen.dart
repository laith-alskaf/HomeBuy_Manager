import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../config/app_dimensions.dart';
import '../../data/models/shopping_item.dart';
import '../../utils/formatters.dart';
import '../../utils/date_utils.dart';
import '../widgets/history/history_calendar_view.dart';
import '../widgets/common/app_info_dialog.dart';

class ShoppingHistoryScreen extends StatefulWidget {
  final List<ShoppingItem> items;
  final Map<String, dynamic> categories;

  const ShoppingHistoryScreen({
    super.key,
    required this.items,
    required this.categories,
  });

  @override
  State<ShoppingHistoryScreen> createState() => _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends State<ShoppingHistoryScreen> {
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 500000);
  DateTime? _selectedMonth;
  DateTime? _selectedDay;
  String _searchQuery = ''; // حقل البحث الجديد
  bool _showChart = false;
  bool _showCalendar = false;
  String _selectedCurrency = 'SYP';
  final List<String> _currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];

  @override
  Widget build(BuildContext context) {
    // 1. استخراج الأشهر المتاحة
    final months =
        widget.items
            .where((i) => i.dateBought != null)
            .map((i) => DateTime(i.dateBought!.year, i.dateBought!.month))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    // 2. تصفية القائمة
    List<ShoppingItem> filteredList = widget.items.where((item) {
      bool catMatch =
          _selectedCategory == null || item.category == _selectedCategory;
      double totalItemPrice = item.price * item.quantity;
      bool priceMatch =
          totalItemPrice >= _priceRange.start &&
          totalItemPrice <= _priceRange.end;

      bool dateMatch = true;
      if (_selectedDay != null) {
        dateMatch =
            item.dateBought != null &&
            item.dateBought!.year == _selectedDay!.year &&
            item.dateBought!.month == _selectedDay!.month &&
            item.dateBought!.day == _selectedDay!.day;
      } else if (_selectedMonth != null) {
        dateMatch =
            item.dateBought != null &&
            item.dateBought!.year == _selectedMonth!.year &&
            item.dateBought!.month == _selectedMonth!.month;
      }

      // فلترة حسب حقل البحث (الاسم أو الملاحظة)
      final matchQuery =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.note.toLowerCase().contains(_searchQuery.toLowerCase());

      // فلترة حسب العملة (مهم جداً للحسابات)
      bool currencyMatch = item.currency == _selectedCurrency;

      return catMatch && priceMatch && dateMatch && matchQuery && currencyMatch;
    }).toList();

    filteredList.sort(
      (a, b) => (b.dateBought ?? DateTime(2000)).compareTo(
        a.dateBought ?? DateTime(2000),
      ),
    );

    double totalExpenses = filteredList.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    // 3. تجهيز بيانات الرسم البياني
    List<PieChartSectionData> chartSections = [];
    if (totalExpenses > 0) {
      Map<String, double> categoryTotals = {};
      for (var item in filteredList) {
        double total = item.price * item.quantity;
        categoryTotals[item.category] =
            (categoryTotals[item.category] ?? 0) + total;
      }

      final sortedEntries = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      chartSections = sortedEntries.map((entry) {
        final catData =
            widget.categories[entry.key] ?? widget.categories['other'];
        final percentage = (entry.value / totalExpenses) * 100;
        return PieChartSectionData(
          color: catData['color'],
          value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // لون خلفية هادئ
      body: CustomScrollView(
        slivers: [
          // 1. AppBar مرن (Sliver)
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  AppInfoDialog.show(
                    context,
                    title: 'أرشيف المشتريات المتقدم (History)',
                    description:
                        'شاشة متكاملة للبحث العميق في بياناتك، تُمكّنك من عصر مصروفاتك والعثور على أي حركة مالية مهما كانت قديمة.',
                    features: [
                      {
                        'title': 'الفلترة المتقدمة',
                        'description':
                            'فلترة دقيقة حسب (العملة، التاريخ، السعر) للوصول المباشر للمعلومات بدقة متناهية.',
                        'icon': Icons.tune_rounded,
                        'color': AppColors.primary,
                      },
                      {
                        'title': 'التقويم الحراري',
                        'description':
                            'استخدم أيقونة "النتيجة" لرؤية استهلاكك اليومي كخريطة حرارية تسهل فهم أنماط الإنفاق الشهرية.',
                        'icon': Icons.calendar_month_rounded,
                        'color': AppColors.accent,
                      },
                      {
                        'title': 'الرسم التفاعلي',
                        'description':
                            'رسم بياني دائري يتشكل في الوقت الفعلي بناءً على نتائج الفلترة التي قمت بتطبيقها للتو.',
                        'icon': Icons.pie_chart_rounded,
                        'color': Colors.purple,
                      },
                    ],
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'أرشيف المشتريات',
                style: AppTypography.body2Medium.copyWith(color: Colors.white),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: Center(
                  child: Icon(
                    Icons.history_edu_rounded,
                    size: 50,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // 2. أدوات الفلترة (Sticky)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusLG),
                ),
                boxShadow: AppColors.softShadow,
              ),
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. حقل البحث (تم نقله للأعلى ليكون الأبرز)
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث في الأرشيف (الاسم أو الملاحظة)...',
                      hintStyle: AppTypography.caption,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.md,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (query) => setState(() => _searchQuery = query),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // فلتر الأشهر
                  if (months.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: months.length + 1,
                        separatorBuilder: (c, i) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildFilterChip(
                              'الكل',
                              _selectedMonth == null && _selectedDay == null,
                              () => setState(() {
                                _selectedMonth = null;
                                _selectedDay = null;
                              }),
                            );
                          }
                          // زر اختيار يوم محدد
                          if (index == 1) {
                            return _buildFilterChip(
                              _selectedDay == null
                                  ? 'يوم محدد'
                                  : DateFormat('dd/MM').format(_selectedDay!),
                              _selectedDay != null,
                              () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDay ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDay = picked;
                                    _selectedMonth = null;
                                  });
                                }
                              },
                              icon: Icons.calendar_today_rounded,
                            );
                          }
                          final date = months[index - 2];
                          return _buildFilterChip(
                            DateFormat('MMM yyyy', 'ar').format(date),
                            _selectedMonth != null &&
                                _selectedMonth!.year == date.year &&
                                _selectedMonth!.month == date.month,
                            () => setState(() {
                              _selectedMonth = date;
                              _selectedDay = null;
                            }),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 15),

                  // اختيار العملة (مهم للتقارير)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _currencies.map((currency) {
                        final isSelected = _selectedCurrency == currency;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(
                              currency,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCurrency = currency);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // فلتر الفئات والسعر
                  Row(
                    children: [
                      // قائمة الفئات
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 45,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              hint: const Text(
                                'كل الفئات',
                                style: TextStyle(fontSize: 14),
                              ),
                              icon: const Icon(
                                Icons.filter_list_rounded,
                                size: 20,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('الكل'),
                                ),
                                ...widget.categories.entries.map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value['label']),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedCategory = val),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // زر الرسم البياني
                      if (totalExpenses > 0)
                        InkWell(
                          onTap: () => setState(() => _showChart = !_showChart),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              color: _showChart
                                  ? AppColors.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _showChart
                                  ? Icons.expand_less_rounded
                                  : Icons.pie_chart_rounded,
                              color: _showChart
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // زر التقويم
                      if (totalExpenses > 0)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showCalendar = !_showCalendar;
                              if (_showCalendar)
                                _showChart =
                                    false; // لا نظهر الاثنين معاً لتوفير المساحة
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              color: _showCalendar
                                  ? AppColors.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _showCalendar
                                  ? Icons.list_rounded
                                  : Icons.calendar_month_rounded,
                              color: _showCalendar
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // شريط السعر (RangeSlider)
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'نطاق السعر: ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_priceRange.start.round()} - ${_priceRange.end.round()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 500000,
                      divisions: 100,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.grey.shade200,
                      labels: RangeLabels(
                        '${_priceRange.start.round()}',
                        '${_priceRange.end.round()}',
                      ),
                      onChanged: (values) =>
                          setState(() => _priceRange = values),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. الرسم البياني (اختياري)
          if (_showChart && totalExpenses > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(AppSpacing.md),
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: PieChart(
                        PieChartData(
                          sections: chartSections,
                          centerSpaceRadius: 20,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إجمالي الفترة',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          FittedBox(
                            alignment: Alignment.centerRight,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatCompactCurrency(totalExpenses) +
                                  ' $_selectedCurrency',
                              style: AppTypography.h5.copyWith(
                                fontWeight: AppTypography.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${filteredList.length} عملية شراء',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_showCalendar)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: HistoryCalendarView(
                  month: _selectedMonth ?? DateTime.now(),
                  items: widget.items,
                  onDaySelected: (date) {
                    setState(() {
                      _selectedDay = date;
                      _selectedMonth = null;
                      _showCalendar = false; // العودة للقائمة لرؤية التفاصيل
                    });
                  },
                ),
              ),
            ),

          // 4. قائمة المشتريات
          if (!_showCalendar)
            filteredList.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد نتائج مطابقة',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredList[index];
                      final catData =
                          widget.categories[item.category] ??
                          widget.categories['other'];

                      return Dismissible(
                        key: ObjectKey(item),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: AppColors.danger,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) {
                          // منطق الحذف هنا (نفس الكود السابق)
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (catData['color'] as Color).withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                catData['icon'],
                                color: catData['color'],
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: AppTypography.body2Medium.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.sticky_note_2_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.note,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  formatDate(item.dateBought!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      formatCompactCurrency(
                                            item.price * item.quantity,
                                          ) +
                                          ' ${item.currency}',
                                      style: AppTypography.body2Medium.copyWith(
                                        fontWeight: AppTypography.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${item.quantity} x ${formatCompactCurrency(item.price)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: filteredList.length),
                  ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  // ويدجت مساعدة للفلتر
  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
