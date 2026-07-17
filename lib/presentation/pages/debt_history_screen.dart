import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../data/models/debt_record.dart';
import '../../utils/formatters.dart';

class DebtHistoryScreen extends StatefulWidget {
  final List<DebtRecord> debts;

  const DebtHistoryScreen({super.key, required this.debts});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen> {
  int _filterIndex = 0; // 0: All, 1: Liabilities, 2: Assets, 3: Settled

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.debts.where((d) {
      if (_filterIndex == 1) return d.type == DebtType.liability;
      if (_filterIndex == 2) return d.type == DebtType.asset;
      if (_filterIndex == 3) return d.isSettled;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الديون', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط الفلترة
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'الكل'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'ديون علي'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'مستحقات لي'),
                  const SizedBox(width: 8),
                  _buildFilterChip(3, 'مكتملة'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final debt = filteredList[index];
                return _buildHistoryCard(debt);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _filterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filterIndex = index),
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black,
      ),
    );
  }

  Widget _buildHistoryCard(DebtRecord debt) {
    final isAsset = debt.type == DebtType.asset;
    final color = isAsset ? Colors.green.shade700 : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: debt.isSettled ? Colors.grey.shade300 : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Icon(
            debt.isSettled
                ? Icons.check_circle
                : (isAsset ? Icons.arrow_upward : Icons.arrow_downward),
            color: debt.isSettled ? Colors.grey : color,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.personName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  debt.isSettled
                      ? 'مكتمل'
                      : 'متبقي: ${formatCurrency(debt.remainingAmount)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(debt.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
