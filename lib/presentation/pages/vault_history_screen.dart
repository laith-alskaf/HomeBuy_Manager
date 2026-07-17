import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../data/models/vault_transaction.dart';
import '../../utils/formatters.dart';

class VaultHistoryScreen extends StatefulWidget {
  final List<VaultTransaction> transactions;

  const VaultHistoryScreen({super.key, required this.transactions});

  @override
  State<VaultHistoryScreen> createState() => _VaultHistoryScreenState();
}

class _VaultHistoryScreenState extends State<VaultHistoryScreen> {
  VaultTransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.transactions.where((t) {
      if (_filterType == null) return true;
      return t.type == _filterType;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final totalIn = widget.transactions
        .where((t) => t.type != VaultTransactionType.manualWithdraw)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalOut = widget.transactions
        .where((t) => t.type == VaultTransactionType.manualWithdraw)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل الخزنة',
          style: AppTypography.h5.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Column(
        children: [
          // 1. ملخص التحليل
          _buildAnalyticsHeader(totalIn, totalOut),

          // 2. شريط الفلترة
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                _buildFilterChip('الكل', null),
                _buildFilterChip('ادخار آلي', VaultTransactionType.autoSave),
                _buildFilterChip(
                  'إيداع يدوي',
                  VaultTransactionType.manualDeposit,
                ),
                _buildFilterChip('سحب', VaultTransactionType.manualWithdraw),
              ],
            ),
          ),

          // 3. القائمة
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filteredList.length,
              itemBuilder: (ctx, index) {
                final transaction = filteredList[index];
                final isIncome =
                    transaction.type != VaultTransactionType.manualWithdraw;
                return _buildTransactionTile(transaction, isIncome);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeader(double totalIn, double totalOut) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderItem(
            'مجموع الوارد',
            formatCurrency(totalIn),
            AppColors.success,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildHeaderItem(
            'مجموع الصادر',
            formatCurrency(totalOut),
            AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: AppTypography.h5.copyWith(
            color: color,
            fontWeight: AppTypography.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VaultTransactionType? type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = selected ? type : null);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black,
      ),
    );
  }

  Widget _buildTransactionTile(VaultTransaction transaction, bool isIncome) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          isIncome
              ? Icons.arrow_circle_up_rounded
              : Icons.arrow_circle_down_rounded,
          color: isIncome ? AppColors.success : AppColors.danger,
          size: 30,
        ),
        title: Text(
          '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount)}',
          style: AppTypography.body1.copyWith(
            color: isIncome ? AppColors.success : AppColors.danger,
            fontWeight: AppTypography.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTypeLabel(transaction.type)),
            if (transaction.note.isNotEmpty)
              Text(
                transaction.note,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          DateFormat('dd/MM/yyyy').format(transaction.date),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  String _getTypeLabel(VaultTransactionType type) {
    switch (type) {
      case VaultTransactionType.autoSave:
        return 'ادخار آلي';
      case VaultTransactionType.manualDeposit:
        return 'إيداع يدوي';
      case VaultTransactionType.manualWithdraw:
        return 'سحب يدوي';
    }
  }
}
