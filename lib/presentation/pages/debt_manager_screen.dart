import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../data/models/debt_record.dart';
import '../../utils/formatters.dart';
import 'debt_history_screen.dart';
import '../../services/budget_service.dart';
import '../../services/categories_service.dart';
import '../../services/notification_service.dart';
import '../widgets/common/app_info_dialog.dart';

class DebtManagerScreen extends StatefulWidget {
  final List<DebtRecord> debts;
  final Function(DebtRecord, bool) onAddDebt;
  final Function(String, double, bool) onAddPayment;
  final Map<String, double> walletBalancesByCurrency;
  final Map<String, double> vaultBalancesByCurrency;
  final bool Function(double, String, {String currency}) onWithdrawFromVault;

  const DebtManagerScreen({
    super.key,
    required this.debts,
    required this.onAddDebt,
    required this.onAddPayment,
    required this.walletBalancesByCurrency,
    required this.vaultBalancesByCurrency,
    required this.onWithdrawFromVault,
  });

  @override
  State<DebtManagerScreen> createState() => _DebtManagerScreenState();
}

class _DebtManagerScreenState extends State<DebtManagerScreen> {
  final BudgetService _budgetService = BudgetService();
  final CategoriesService _categoriesService = CategoriesService();
  String _selectedDisplayCurrency = 'SYP';
  final List<String> _currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ترتيب الديون تنازلياً (الأحدث أولاً) بناءً على المعرف الذي يمثل التوقيت
    // تصفية وحساب المجموع بناءً على العملة المختارة للعرض
    final activeDebts =
        widget.debts
            .where(
              (d) => !d.isSettled && d.currency == _selectedDisplayCurrency,
            )
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id));

    final totalAssets = widget.debts
        .where(
          (d) =>
              d.type == DebtType.asset &&
              !d.isSettled &&
              d.currency == _selectedDisplayCurrency,
        )
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
    final totalLiabilities = widget.debts
        .where(
          (d) =>
              d.type == DebtType.liability &&
              !d.isSettled &&
              d.currency == _selectedDisplayCurrency,
        )
        .fold(0.0, (sum, d) => sum + d.remainingAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الديون والمستحقات',
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
                title: 'إدارة الديون والتسويات (Debts)',
                description:
                    'شاشة متكاملة للمحاسبة السريعة بينك وبين الآخرين، مع تسجيل دقيق للسلف والدفعات المتعددة العملات.',
                features: [
                  {
                    'title': 'تصنيف الديون',
                    'description':
                        'فصل واضح بين "ديون لي" و "ديون عليّ" مع تلخيص إجمالي دقيق حسب العملة المختارة.',
                    'icon': Icons.swap_vert_rounded,
                    'color': AppColors.primary,
                  },
                  {
                    'title': 'ربط المحفظة',
                    'description':
                        'عند الإقراض أو السداد، يمكنك تحديث رصيد "المحفظة الذكية" تلقائياً لضمان دقة ميزانيتك.',
                    'icon': Icons.account_balance_wallet_rounded,
                    'color': AppColors.success,
                  },
                  {
                    'title': 'تعدد العملات',
                    'description':
                        'سجل الديون بأي عملة (USD, SYP, etc) وتابعها بسهولة من خلال فلتر العملات العلوي.',
                    'icon': Icons.currency_exchange_rounded,
                    'color': Colors.amber,
                  },
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            tooltip: 'سجل الديون',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DebtHistoryScreen(debts: widget.debts),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // اختيار عملة العرض
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _currencies.map((currency) {
                  final isSelected = _selectedDisplayCurrency == currency;
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
                          setState(() => _selectedDisplayCurrency = currency);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // 1. لوحة المعلومات
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'مستحقاتي (لي)',
                    totalAssets,
                    Colors.green.shade700,
                    Icons.arrow_circle_up_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'ديون (علي)',
                    totalLiabilities,
                    AppColors.danger,
                    Icons.arrow_circle_down_rounded,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          _buildAgingReport(activeDebts),
          const Divider(height: 1),

          // 2. القائمة النشطة
          Expanded(
            child: activeDebts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeDebts.length,
                    itemBuilder: (ctx, index) =>
                        _buildDebtCard(activeDebts[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        label: const Text('دين جديد', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(DebtRecord debt) {
    final isAsset = debt.type == DebtType.asset;
    final color = isAsset ? Colors.green.shade700 : AppColors.danger;
    final dateAdded = DateTime.tryParse(debt.id) ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaymentDialog(debt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(
                          isAsset ? Icons.person_add : Icons.person_remove,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
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
                            'تاريخ الدين: ${DateFormat('dd/MM/yyyy').format(dateAdded)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'استحقاق: ${DateFormat('dd/MM/yyyy').format(debt.dueDate)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatCurrency(debt.remainingAmount)} ${debt.currency}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'من أصل ${formatCurrency(debt.totalAmount)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: debt.progress,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                'تم سداد ${(debt.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد ديون جارية',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DebtType selectedType = DebtType.liability;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    bool updateWallet = true;
    String _selectedCurrency = 'SYP';

    final bool? debtAdded = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('إضافة سجل جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الشخص',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ الإجمالي',
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        underline: const SizedBox(),
                        items: _currencies
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<DebtType>(
                        title: const Text(
                          'عليّ (دين)',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: DebtType.liability,
                        groupValue: selectedType,
                        onChanged: (val) => setState(() => selectedType = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<DebtType>(
                        title: const Text(
                          'لي (مستحق)',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: DebtType.asset,
                        groupValue: selectedType,
                        onChanged: (val) => setState(() => selectedType = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                ListTile(
                  title: const Text('تاريخ الاستحقاق'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
                CheckboxListTile(
                  title: Text(
                    selectedType == DebtType.asset
                        ? 'خصم المبلغ من المحفظة الآن؟'
                        : 'إضافة المبلغ للمحفظة الآن؟',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: updateWallet,
                  onChanged: (val) => setState(() => updateWallet = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = parseFormattedNumber(amountController.text);

                // التحقق من الرصيد عند الإقراض (Asset) وتحديث المحفظة
                if (selectedType == DebtType.asset && updateWallet) {
                  final canProceed = await _checkAndResolveBalance(
                    amount,
                    nameController.text,
                    _selectedCurrency,
                  );
                  if (!canProceed) return;
                }

                if (nameController.text.isNotEmpty && amount > 0) {
                  final newDebt = DebtRecord(
                    id: DateTime.now().toString(),
                    personName: nameController.text,
                    totalAmount: amount,
                    currency: _selectedCurrency,
                    type: selectedType,
                    dueDate: selectedDate,
                  );
                  widget.onAddDebt(newDebt, updateWallet);
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (debtAdded == true) {
      setState(() {});
    }
  }

  /// دالة للتحقق من الرصيد الحر ومعالجة العجز
  Future<bool> _checkAndResolveBalance(
    double amount,
    String personName,
    String currency,
  ) async {
    // 1. حساب الرصيد المخصص للميزانيات (فقط إذا كانت العملة SYP لأن الميزانية بالليرة السورية حالياً)
    double totalAllocated = 0;
    if (currency == 'SYP') {
      final categories = _categoriesService.categories;
      for (var key in categories.keys) {
        totalAllocated += _budgetService.getLimit(key);
      }
    }

    // 2. حساب الرصيد الحر (غير المخصص) للعملة المحددة
    final currentWalletBal = widget.walletBalancesByCurrency[currency] ?? 0.0;
    final unallocatedBalance = currentWalletBal - totalAllocated;

    // 3. إذا كان المبلغ المطلوب متوفراً في الرصيد الحر، نتابع
    if (amount <= unallocatedBalance) {
      return true;
    }

    final deficit = amount - unallocatedBalance;
    final currentVaultBal = widget.vaultBalancesByCurrency[currency] ?? 0.0;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('رصيد حر غير كافٍ'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المبلغ المطلوب يتجاوز الرصيد غير المخصص للميزانيات.'),
                const SizedBox(height: 10),
                Text(
                  '• الرصيد الحر: ${formatCurrency(unallocatedBalance)} $currency',
                ),
                Text(
                  '• العجز: ${formatCurrency(deficit)} $currency',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'كيف تريد تغطية العجز؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              // خيار 1: السحب من الخزنة
              if (currentVaultBal >= deficit)
                TextButton.icon(
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('سحب من الخزنة'),
                  onPressed: () {
                    widget.onWithdrawFromVault(
                      deficit,
                      'تغطية دين لـ: $personName',
                      currency: currency,
                    );
                    Navigator.pop(ctx, true);
                  },
                ),

              // خيار 2: الخصم من ميزانية فئة
              TextButton.icon(
                icon: const Icon(Icons.pie_chart_outline_rounded, size: 16),
                label: const Text('خصم من فئة'),
                onPressed: () async {
                  // البحث عن الفئات التي تغطي العجز
                  final categories = _categoriesService.categories;
                  final validCategories = categories.keys
                      .where((key) => _budgetService.getLimit(key) >= deficit)
                      .toList();

                  if (validCategories.isEmpty) {
                    NotificationService().showError(
                      context,
                      'لا توجد فئة بها رصيد كافٍ لتغطية العجز',
                    );
                    return;
                  }

                  // عرض قائمة اختيار بسيطة
                  final selectedCat = await showDialog<String>(
                    context: context,
                    builder: (subCtx) => SimpleDialog(
                      title: const Text('اختر الفئة للخصم منها'),
                      children: validCategories
                          .map(
                            (key) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(subCtx, key),
                              child: Text(
                                '${_categoriesService.categories[key]['label']} (${formatCurrency(_budgetService.getLimit(key))})',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );

                  if (selectedCat != null) {
                    final currentLimit = _budgetService.getLimit(selectedCat);
                    await _budgetService.setLimit(
                      selectedCat,
                      currentLimit - deficit,
                    );
                    Navigator.pop(ctx, true);
                  }
                },
              ),

              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPaymentDialog(DebtRecord debt) async {
    final amountController = TextEditingController();
    bool updateWallet = true;
    String? errorText;

    final bool? paymentAdded = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('تسجيل دفعة: ${debt.personName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المبلغ المتبقي: ${formatCurrency(debt.remainingAmount)}'),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'مبلغ الدفعة',
                  suffixText: debt.currency,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: Text(
                  debt.type == DebtType.liability
                      ? 'خصم من المحفظة؟'
                      : 'إيداع في المحفظة؟',
                  style: const TextStyle(fontSize: 12),
                ),
                value: updateWallet,
                onChanged: (val) => setState(() => updateWallet = val!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = parseFormattedNumber(amountController.text);

                if (amount > debt.remainingAmount) {
                  setState(
                    () => errorText =
                        'المبلغ أكبر من المتبقي (${formatCurrency(debt.remainingAmount)})',
                  );
                  return;
                }

                if (amount > 0) {
                  widget.onAddPayment(debt.id, amount, updateWallet);
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('تسجيل'),
            ),
          ],
        ),
      ),
    );

    if (paymentAdded == true) {
      setState(() {});
    }
  }

  Widget _buildAgingReport(List<DebtRecord> debts) {
    if (debts.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    int upToDateCount = 0;
    int overdue1to30 = 0;
    int overdue31to60 = 0;
    int overdue60Plus = 0;

    for (var debt in debts) {
      if (debt.dueDate.isAfter(now)) {
        upToDateCount++;
      } else {
        final diff = now.difference(debt.dueDate).inDays;
        if (diff <= 30) {
          overdue1to30++;
        } else if (diff <= 60) {
          overdue31to60++;
        } else {
          overdue60Plus++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أعمار الديون (Aging Report)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAgingItem('منتظم', upToDateCount, Colors.green),
              _buildAgingItem('1-30 يوم', overdue1to30, Colors.orange),
              _buildAgingItem('31-60 يوم', overdue31to60, Colors.deepOrange),
              _buildAgingItem('+60 يوم', overdue60Plus, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgingItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
