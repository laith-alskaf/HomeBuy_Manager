import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../data/models/wallet_transaction.dart';
import '../../utils/formatters.dart';
import '../../utils/date_utils.dart';

class DepositsHistorySheet extends StatefulWidget {
  final List<WalletTransaction> deposits;
  final VoidCallback onEditLast;

  const DepositsHistorySheet({
    super.key,
    required this.deposits,
    required this.onEditLast,
  });

  @override
  State<DepositsHistorySheet> createState() => _DepositsHistorySheetState();
}

class _DepositsHistorySheetState extends State<DepositsHistorySheet> {
  DateTime? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    // 1. استخراج وتجهيز قائمة الأشهر
    final months = widget.deposits
        .map((d) => DateTime(d.date.year, d.date.month))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // 2. الفلترة
    final filteredDeposits = _selectedMonth == null
        ? widget.deposits
        : widget.deposits
            .where((d) =>
                d.date.year == _selectedMonth!.year &&
                d.date.month == _selectedMonth!.month)
            .toList();

    // 3. ترتيب العرض (الأحدث أولاً)
    final displayList = List.of(filteredDeposits)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      height: 500, // زيادة الطول قليلاً لراحة العين
      child: Column(
        children: [
          // مقبض السحب
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.history_rounded, color: AppColors.success),
              ),
              const SizedBox(width: 10),
              Text(
                'سجل العمليات',
                style: AppTypography.h5.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              const Spacer(),
              // عرض إجمالي المبلغ المعروض
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'عدد العمليات: ${displayList.length}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // شريط الفلترة
          if (months.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: months.length + 1, // +1 لزر "الكل"
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  if (index == 0) {
                    final isSelected = _selectedMonth == null;
                    return _buildFilterChip(
                      label: 'الكل',
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedMonth = null),
                    );
                  }
                  final date = months[index - 1];
                  final isSelected = _selectedMonth != null &&
                      _selectedMonth!.year == date.year &&
                      _selectedMonth!.month == date.month;

                  return _buildFilterChip(
                    label: DateFormat('MMMM yyyy', 'ar').format(date),
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedMonth = date),
                  );
                },
              ),
            ),

          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // القائمة مع أنيميشن
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: displayList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      // مفتاح ليعرف AnimatedSwitcher أن القائمة تغيرت
                      key:
                          ValueKey<String>(_selectedMonth?.toString() ?? 'all'),
                      itemCount: displayList.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (ctx, i) {
                        final deposit = displayList[i];
                        // تم تعطيل التعديل بناءً على الطلب (isEditable = false)
                        return _buildTransactionCard(deposit, false);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت الفلتر المحسنة
  Widget _buildFilterChip(
      {required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.success : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.success : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ودجت بطاقة العملية
  Widget _buildTransactionCard(WalletTransaction deposit, bool isEditable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة السهم
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_downward_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 15),

          // تفاصيل العملية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deposit.note.isEmpty ? 'إيداع رصيد' : deposit.note,
                  style: AppTypography.body2Medium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(
                      deposit.date), // تأكد أن لديك دالة لتنسيق الوقت والتاريخ
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),

          // المبلغ وزر التعديل
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${formatCurrency(deposit.amount)} ${deposit.currency}',
                style: AppTypography.body1.copyWith(
                  color: AppColors.success,
                ),
              ),
              if (isEditable) ...[
                const SizedBox(height: 5),
                InkWell(
                  onTap: widget.onEditLast,
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_rounded, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('تعديل',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // حالة القائمة الفارغة
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey.shade200),
        const SizedBox(height: 10),
        Text(
          'لا توجد عمليات في هذه الفترة',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
      ],
    );
  }
}
