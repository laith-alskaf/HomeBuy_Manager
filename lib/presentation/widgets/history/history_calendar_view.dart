import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/shopping_item.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../utils/formatters.dart';

class HistoryCalendarView extends StatelessWidget {
  final DateTime month;
  final List<ShoppingItem> items;
  final Function(DateTime) onDaySelected;

  const HistoryCalendarView({
    super.key,
    required this.month,
    required this.items,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. حساب تفاصيل الشهر المختار
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);

    // يوم الأسبوع الأول (1 = الاثنين ... 7 = الأحد)
    // سنجعل الأحد هو بداية الأسبوع كالمعتاد
    int firstWeekday = firstDayOfMonth.weekday;
    if (firstWeekday == 7) firstWeekday = 0; // الأحد = 0 في طريقتنا

    // تجميع المصاريف حسب اليوم
    final Map<int, double> dailyExpenses = {};
    for (var item in items) {
      if (item.isBought &&
          item.dateBought != null &&
          item.dateBought!.year == month.year &&
          item.dateBought!.month == month.month) {
        final day = item.dateBought!.day;
        dailyExpenses[day] =
            (dailyExpenses[day] ?? 0) + (item.price * item.quantity);
      }
    }

    // إيجاد أقصى قيمة تلوين (التصنيف الحراري)
    double maxDayExpense = 0;
    if (dailyExpenses.isNotEmpty) {
      maxDayExpense = dailyExpenses.values.reduce((a, b) => a > b ? a : b);
    }

    final weekdays = [
      'أحد',
      'إثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
      'سبت',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat('MMMM yyyy', 'ar').format(month),
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map(
                  (day) => Text(
                    day,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: daysInMonth + firstWeekday,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox(); // خلايا فارغة قبل بداية الشهر
              }

              final dayNumber = index - firstWeekday + 1;
              final expense = dailyExpenses[dayNumber] ?? 0;
              final hasExpense = expense > 0;

              // حساب اللون الحراري (من الأخضر الفاتح إلى الأحمر الغامق بناءً على الصرف)
              Color dayColor = Colors.grey.shade100;
              Color textColor = AppColors.textDark;

              if (hasExpense && maxDayExpense > 0) {
                final ratio = expense / maxDayExpense;
                if (ratio > 0.75) {
                  dayColor = Colors.red.shade400;
                  textColor = Colors.white;
                } else if (ratio > 0.4) {
                  dayColor = Colors.orange.shade300;
                  textColor = Colors.white;
                } else {
                  dayColor = AppColors.primary.withOpacity(0.4);
                  textColor = Colors.white;
                }
              }

              final DateTime currentDate = DateTime(
                month.year,
                month.month,
                dayNumber,
              );
              final isToday =
                  currentDate.year == DateTime.now().year &&
                  currentDate.month == DateTime.now().month &&
                  currentDate.day == DateTime.now().day;

              return InkWell(
                onTap: hasExpense ? () => onDaySelected(currentDate) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: dayColor,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: isToday || hasExpense
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      if (hasExpense) ...[
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatCompactCurrency(expense),
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          if (dailyExpenses.isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.red.shade400, 'مصروف عالي'),
                const SizedBox(width: 15),
                _buildLegendItem(
                  AppColors.primary.withOpacity(0.4),
                  'مصروف بسيط',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
