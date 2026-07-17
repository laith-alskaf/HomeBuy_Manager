import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../config/app_dimensions.dart';
import '../../services/budget_service.dart';
import '../../services/categories_service.dart';
import '../../utils/formatters.dart';
import '../../data/models/shopping_item.dart';
import '../../services/notification_service.dart';
import '../widgets/common/animated_button.dart';

class BudgetSetupDialog extends StatefulWidget {
  // لم نعد بحاجة لتمرير الفئات لأننا سنجلبها من الخدمة مباشرة لتحديثها عند الإضافة
  final Map<String, double> currentSpending;
  final List<ShoppingItem> allItems;
  final double totalWalletBalance;

  const BudgetSetupDialog({
    super.key,
    required this.currentSpending,
    required this.allItems,
    required this.totalWalletBalance,
  });

  @override
  State<BudgetSetupDialog> createState() => _BudgetSetupDialogState();
}

class _BudgetSetupDialogState extends State<BudgetSetupDialog> {
  final BudgetService _budgetService = BudgetService();
  final CategoriesService _categoriesService = CategoriesService();

  late Map<String, dynamic> _currentCategories;

  double _totalAllocated = 0.0;
  final Map<String, double> _tempBudgets = {};

  @override
  void initState() {
    super.initState();
    _currentCategories = _categoriesService.categories;
    _calculateInitialTotal();
  }

  void _calculateInitialTotal() {
    _totalAllocated = 0.0;
    for (var key in _currentCategories.keys) {
      final val = _budgetService.getLatestBudgetForCategory(key);
      _tempBudgets[key] = val;
      _totalAllocated += val;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'ar').format(now);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 600,
        child: Column(
          children: [
            _buildBalanceSummaryCard(),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ميزانية شهر',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      monthName,
                      style: AppTypography.h5.copyWith(
                        fontWeight: AppTypography.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary, size: 28),
                  tooltip: 'إضافة فئة جديدة',
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _currentCategories.length,
                separatorBuilder: (c, i) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final key = _currentCategories.keys.elementAt(index);
                  final catData = _currentCategories[key];

                  final autoFillLimit =
                      _budgetService.getLatestBudgetForCategory(key);
                  final spent = widget.currentSpending[key] ?? 0.0;
                  final isCustom = key.startsWith('custom_');

                  final currentVal = _tempBudgets[key] ?? 0.0;
                  final otherAllocated = _totalAllocated - currentVal;
                  final maxLimit = widget.totalWalletBalance - otherAllocated;

                  return Row(
                    children: [
                      Expanded(
                        child: _BudgetInputRow(
                          categoryKey: key,
                          categoryName: catData['label'],
                          categoryColor: catData['color'],
                          initialValue: autoFillLimit,
                          minLimit: spent,
                          maxLimit: maxLimit,
                          onChanged: (val) {
                            _budgetService.setLimit(key, val);
                            setState(() {
                              _tempBudgets[key] = val;
                              _totalAllocated = _tempBudgets.values
                                  .fold(0.0, (sum, v) => sum + v);
                            });
                          },
                        ),
                      ),
                      if (isCustom)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.grey, size: 20),
                          onPressed: () =>
                              _deleteCategory(key, catData['label']),
                          tooltip: 'حذف الفئة',
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: () => Navigator.pop(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: AppDimensions.elevationSM,
                child: Center(
                  child: Text(
                    'حفظ وإغلاق',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت لعرض ملخص الرصيد والميزانيات
  Widget _buildBalanceSummaryCard() {
    final remainingUnallocated = widget.totalWalletBalance - _totalAllocated;
    final isOverBudget = remainingUnallocated < 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isOverBudget
            ? AppColors.danger.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isOverBudget
              ? AppColors.danger.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'رصيد المحفظة',
            formatCurrency(widget.totalWalletBalance),
            AppColors.textDark,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildSummaryItem(
            'تم تخصيصه',
            formatCurrency(_totalAllocated),
            Colors.blue.shade700,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildSummaryItem(
            'غير مخصص',
            formatCurrency(remainingUnallocated),
            isOverBudget ? AppColors.danger : Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // منطق حذف الفئة
  void _deleteCategory(String id, String name) async {
    // التحقق مما إذا كانت الفئة مستخدمة في أي عملية شراء (سابقة أو حالية)
    final isUsed = widget.allItems.any((item) => item.category == id);

    if (isUsed) {
      NotificationService().showError(
        context,
        'لا يمكن حذف "$name" لوجود مشتريات مسجلة بها.',
      );
    } else {
      await _categoriesService.deleteCustomCategory(id);
      setState(() {
        _currentCategories = _categoriesService.categories;
      });
      if (mounted) {
        NotificationService().showSuccess(context, 'تم حذف الفئة بنجاح');
      }
    }
  }

  // نافذة إضافة فئة جديدة
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة فئة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'اسم الفئة', hintText: 'مثلاً: فواتير، تعليم...'),
            ),
            const SizedBox(height: 20),
            // هنا يمكن إضافة منتقي ألوان وأيقونات بسيط (للتبسيط سنستخدم قيم افتراضية أو عشوائية)
            const Text('سيتم تعيين لون وأيقونة افتراضية',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _categoriesService.addCustomCategory(
                    nameController.text,
                    Colors.primaries[nameController.text.length %
                        Colors.primaries.length], // لون عشوائي
                    Icons.local_offer_outlined);
                setState(() {
                  _currentCategories = _categoriesService.categories;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _BudgetInputRow extends StatefulWidget {
  final String categoryKey;
  final String categoryName;
  final Color categoryColor;
  final double initialValue;
  final Function(double) onChanged;
  final double minLimit;
  final double maxLimit;

  const _BudgetInputRow({
    required this.categoryKey,
    required this.categoryName,
    required this.categoryColor,
    required this.initialValue,
    required this.onChanged,
    required this.minLimit,
    required this.maxLimit,
  });

  @override
  State<_BudgetInputRow> createState() => _BudgetInputRowState();
}

class _BudgetInputRowState extends State<_BudgetInputRow> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // تهيئة الحقل بالقيمة السابقة مع التنسيق
    String text =
        widget.initialValue > 0 ? formatCurrency(widget.initialValue) : '';
    _controller = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
            backgroundColor: widget.categoryColor.withOpacity(0.2),
            radius: 20,
            child: Icon(Icons.category, size: 18, color: widget.categoryColor)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(widget.categoryName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14))),
        SizedBox(
          width: 140,
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'بلا حد',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              suffixText: 'ل.س',
              suffixStyle: const TextStyle(fontSize: 10),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              errorText: _errorText,
              errorStyle: const TextStyle(height: 0.8, fontSize: 10),
            ),
            onChanged: (val) {
              final numericVal = parseFormattedNumber(val);
              if (numericVal > widget.maxLimit) {
                setState(() {
                  final double displayMax =
                      widget.maxLimit < 0 ? 0.0 : widget.maxLimit;
                  _errorText = 'تجاوز الرصيد (${formatCurrency(displayMax)})';
                });
              } else if (numericVal > 0 && numericVal < widget.minLimit) {
                setState(() {
                  _errorText =
                      'أقل من المصروف (${formatCurrency(widget.minLimit)})';
                });
              } else {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
                widget.onChanged(numericVal);
              }
            },
          ),
        ),
      ],
    );
  }
}
