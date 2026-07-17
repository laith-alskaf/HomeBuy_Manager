import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/fixed_bill.dart';
import '../../data/models/shopping_item.dart';
import '../../data/services/local_storage_service.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../widgets/common/app_info_dialog.dart';

class BillsManagerScreen extends StatefulWidget {
  const BillsManagerScreen({super.key});

  @override
  State<BillsManagerScreen> createState() => _BillsManagerScreenState();
}

class _BillsManagerScreenState extends State<BillsManagerScreen> {
  final LocalStorageService _storageService = LocalStorageService();

  List<FixedBill> _bills = [];
  String _currentCycleId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // استخدام الشهر الحالي كـ Cycle ID افتراضي إذا لم يكن هناك دورة
    final now = DateTime.now();
    final defaultCycle = '${now.year}-${now.month}';
    _currentCycleId = prefs.getString('cycle_start_date') ?? defaultCycle;

    _bills = await _storageService.loadFixedBills();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBills() async {
    await _storageService.saveFixedBills(_bills);
    setState(() {});
  }

  void _showAddBillDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'أخرى';
    String selectedCurrency = 'SYP';
    String selectedFrequency = 'monthly';
    bool isAutoPay = false;

    final categories = [
      'سكن',
      'كهرباء',
      'إنترنت',
      'اتصالات',
      'اشتراكات',
      'أخرى',
    ];

    final currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];
    final frequencies = {
      'weekly': 'أسبوعياً',
      'monthly': 'شهرياً',
      'quarterly': 'ربع سنوي',
      'yearly': 'سنوياً',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة التزام جديد', textAlign: TextAlign.center),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الالتزام',
                    hintText: 'مثال: إيجار المنزل',
                    prefixIcon: const Icon(Icons.receipt_long_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        ),
                        items: currencies
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setDialogState(() => selectedCurrency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'تكرار الدفع',
                    suffixIcon: const Icon(Icons.repeat_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  items: frequencies.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setDialogState(() => selectedFrequency = val);
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'التصنيف',
                    prefixIcon: const Icon(Icons.category_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('دفع تلقائي'),
                  subtitle: const Text('سيتم الخصم تلقائياً عند بدء الدورة'),
                  value: isAutoPay,
                  onChanged: (val) => setDialogState(() => isAutoPay = val),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    amountController.text.isEmpty)
                  return;
                final amount = double.tryParse(amountController.text) ?? 0.0;

                final newBill = FixedBill(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  amount: amount,
                  currency: selectedCurrency,
                  frequency: selectedFrequency,
                  category: selectedCategory,
                  isAutoPay: isAutoPay,
                );

                setState(() {
                  _bills.add(newBill);
                });
                await _saveBills();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'إضافة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBill(FixedBill bill, String action) async {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      if (action == 'pay') {
        // إنشاء مصروف في سجل المشتريات بالعملة الصحيحة
        final shoppingItems = await _storageService.loadShoppingList();
        shoppingItems.add(
          ShoppingItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: bill.name,
            price: bill.amount,
            currency: bill.currency,
            quantity: 1,
            category: bill.category,
            note: 'دفع التزام ثابت (${_getFreqName(bill.frequency)})',
            dateBought: DateTime.now(),
            isBought: true,
          ),
        );
        await _storageService.saveShoppingList(shoppingItems);

        _bills[index].statusHistory[_currentCycleId] = 'paid';
      } else if (action == 'skip') {
        _bills[index].statusHistory[_currentCycleId] = 'skipped';
      }

      await _saveBills();

      if (mounted) {
        String msg = action == 'pay'
            ? 'تم الدفع وخصم ${bill.amount} ${bill.currency} من المحفظة'
            : 'تم تخطي الدفع لهذه الدورة';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: action == 'pay'
                ? AppColors.success
                : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _getFreqName(String freq) {
    switch (freq) {
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      case 'quarterly':
        return 'ربع سنوي';
      case 'yearly':
        return 'سنوي';
      default:
        return freq;
    }
  }

  Future<void> _undoBill(FixedBill bill) async {
    final status = bill.statusHistory[_currentCycleId];
    if (status == null) return;

    setState(() {
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index].statusHistory.remove(_currentCycleId);
      }
    });
    await _saveBills();

    if (status == 'paid') {
      final shoppingItems = await _storageService.loadShoppingList();
      final prefs = await SharedPreferences.getInstance();
      final cycleStr = prefs.getString('cycle_start_date');
      final cycleStart = cycleStr != null
          ? (DateTime.tryParse(cycleStr) ?? DateTime.now())
          : DateTime.now().subtract(const Duration(days: 30));

      final indexToRemove = shoppingItems.lastIndexWhere(
        (item) =>
            item.name == bill.name &&
            item.price == bill.amount &&
            item.currency == bill.currency &&
            item.dateBought != null &&
            item.dateBought!.isAfter(cycleStart),
      );

      if (indexToRemove != -1) {
        shoppingItems.removeAt(indexToRemove);
        await _storageService.saveShoppingList(shoppingItems);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التراجع وحذف المصروف من المحفظة'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteBill(FixedBill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الالتزام'),
        content: Text('هل أنت متأكد من حذف "${bill.name}" بشكل نهائي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الآن', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _bills.removeWhere((b) => b.id == bill.id);
      });
      await _saveBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pendingBills = _bills
        .where((b) => b.statusHistory[_currentCycleId] == null)
        .toList();
    final processedBills = _bills
        .where((b) => b.statusHistory[_currentCycleId] != null)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'الالتزامات الثابتة',
          style: AppTypography.h5.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfo(),
          ),
        ],
      ),
      body: _bills.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (pendingBills.isNotEmpty) ...[
                  _buildHeader('بانتظار الدفع', AppColors.textDark),
                  const SizedBox(height: 12),
                  ...pendingBills.map(_buildBillCard),
                  const SizedBox(height: 24),
                ],
                if (processedBills.isNotEmpty) ...[
                  _buildHeader('مكتملة', AppColors.textLight),
                  const SizedBox(height: 12),
                  ...processedBills.map(_buildBillCard),
                  const SizedBox(height: 30),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBillDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'التزام جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader(String title, Color color) {
    return Text(
      title,
      style: AppTypography.h6.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد التزامات مسجلة',
            style: AppTypography.h6.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أضف فواتيرك المتكررة لتذكيرك بها',
            style: AppTypography.body2.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(FixedBill bill) {
    final status = bill.statusHistory[_currentCycleId];
    final isPaid = status == 'paid';
    final isPending = status == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () => _deleteBill(bill),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          _getCategoryIcon(bill.category),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.name,
                              style: AppTypography.body1Medium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (bill.isAutoPay)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'دفع تلقائي',
                                    style: TextStyle(
                                      color: Colors.amber.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            Text(
                              '${_getFreqName(bill.frequency)} • ${bill.category}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bill.amount.toStringAsFixed(0),
                            style: AppTypography.currency.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bill.currency,
                            style: AppTypography.overline.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isPending)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _processBill(bill, 'pay'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('دفع الآن'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _processBill(bill, 'skip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('تخطي'),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! < -500) {
                          // سحب لليسار بالعربي
                          _undoBill(bill);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppColors.success.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPaid ? Icons.check_circle : Icons.skip_next,
                              color: isPaid ? AppColors.success : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPaid ? 'تم الدفع' : 'تم التخطي',
                              style: TextStyle(
                                color: isPaid
                                    ? AppColors.success
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.swipe_left,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const Text(
                              ' للتراجع',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'سكن':
        return Icons.home_rounded;
      case 'كهرباء':
        return Icons.bolt_rounded;
      case 'إنترنت':
        return Icons.wifi_rounded;
      case 'اتصالات':
        return Icons.phone_android_rounded;
      case 'اشتراكات':
        return Icons.subscriptions_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  void _showInfo() {
    AppInfoDialog.show(
      context,
      title: 'الالتزامات الثابتة (Recurring Bills)',
      description:
          'نظام ذكي لتتبع فواتيرك واشتراكاتك الدورية المنظمة للشهر، وضمان دفعها في وقتها بصورة احترافية.',
      features: [
        {
          'title': 'تعدد التواتر',
          'description':
              'ادعم كافة أنواع الاشتراكات (يومية، أسبوعية، شهرية) لتنظيم ميزانيتك بدقة متناهية.',
          'icon': Icons.event_repeat_rounded,
          'color': Colors.purple,
        },
        {
          'title': 'تعدد العملات',
          'description':
              'بإمكانك تحديد عملة كل فاتورة؛ عند الدفع سيم الخصم من الرصيد المقابل في المحفظة.',
          'icon': Icons.currency_exchange_rounded,
          'color': AppColors.primary,
        },
        {
          'title': 'التحكم المرن',
          'description':
              'مرونة الالتزامات؛ يمكنك "تخطي" دفعة معينة أو التراجع عنها لسحب المبلغ للمحفظة مجدداً.',
          'icon': Icons.undo_rounded,
          'color': Colors.orange,
        },
      ],
    );
  }
}
