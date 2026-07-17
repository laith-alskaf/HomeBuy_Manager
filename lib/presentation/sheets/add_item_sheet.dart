import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../data/models/shopping_item.dart';
import '../../services/notification_service.dart';
import '../../utils/formatters.dart';

class AddItemSheet extends StatefulWidget {
  final Function(String, String, double, int, String, String) onAdd;
  final Map<String, dynamic> categories;
  final Map<String, List<String>> suggestedItems;
  final ShoppingItem? existingItem;
  final Map<String, double> balancesByCurrency;
  final Function(String, String)? getLastPrice;

  const AddItemSheet({
    super.key,
    required this.onAdd,
    required this.categories,
    required this.suggestedItems,
    this.existingItem,
    required this.balancesByCurrency,
    this.getLastPrice,
  });

  static Future<dynamic> show(
    BuildContext context, {
    required Function(String, String, double, int, String, String) onAdd,
    required Map<String, dynamic> categories,
    required Map<String, List<String>> suggestedItems,
    ShoppingItem? existingItem,
    required Map<String, double> balancesByCurrency,
    Function(String, String)? getLastPrice,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        onAdd: onAdd,
        categories: categories,
        suggestedItems: suggestedItems,
        existingItem: existingItem,
        balancesByCurrency: balancesByCurrency,
        getLastPrice: getLastPrice,
      ),
    );
  }

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();

  String? _selectedCategory;
  int _quantity = 1;
  double _currentPrice = 0.0;
  String _selectedCurrency = 'SYP';
  bool _isSaving = false;
  final List<String> _currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!.name;
      _currentPrice = widget.existingItem!.price;
      _priceController.text = _currentPrice == 0
          ? ''
          : formatCurrency(_currentPrice);
      _selectedCategory = widget.existingItem!.category;
      _quantity = widget.existingItem!.quantity;
      _noteController.text = widget.existingItem!.note;
      _selectedCurrency = widget.existingItem!.currency;
    }

    _priceController.addListener(() {
      setState(() {
        _currentPrice = parseFormattedNumber(_priceController.text);
      });
    });

    _nameController.addListener(() {
      setState(() {}); // Trigger rebuild to update suggestions as user types
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  // حساب الإجمالي لحظياً
  double get _totalEstimated => _currentPrice * _quantity;
  // التحقق من تجاوز الميزانية
  double get _currentBalance =>
      widget.balancesByCurrency[_selectedCurrency] ?? 0.0;
  bool get _isOverBudget => _totalEstimated > _currentBalance;

  @override
  Widget build(BuildContext context) {
    // قائمة الاقتراحات الحالية بناءً على البحث والقسم
    List<String> allSuggested = [];
    if (_selectedCategory != null) {
      allSuggested = widget.suggestedItems[_selectedCategory] ?? [];
    } else {
      allSuggested = widget.suggestedItems.values
          .expand((e) => e)
          .toSet()
          .toList();
    }

    final query = _nameController.text.trim().toLowerCase();
    List<String> currentSuggestions = allSuggested;
    if (query.isNotEmpty) {
      currentSuggestions = allSuggested
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // مقبض السحب (Handle)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 25),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingItem != null ? 'تعديل المنتج' : 'إضافة جديد',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (_isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'تجاوزت الرصيد',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // 1. اختيار القسم (شريط أفقي بدلاً من Dropdown)
            const Text(
              'اختر القسم',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90, // ارتفاع ثابت للشريط
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entry = widget.categories.entries.elementAt(index);
                  final isSelected = _selectedCategory == entry.key;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = entry.key;
                        if (widget.existingItem == null) {
                          _nameController.clear();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 70,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? entry.value['color'].withOpacity(0.15)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? entry.value['color']
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            entry.value['icon'],
                            color: isSelected
                                ? entry.value['color']
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            entry.value['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? entry.value['color']
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 2. حقل الاسم والمقترحات
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'اسم المنتج',
                hintText: 'مثلاً: خبز، حليب...',
                prefixIcon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.textLight,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            // أنيميشن للمقترحات (تظهر أثناء الكتابة أو عند اختيار قسم)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: (currentSuggestions.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentSuggestions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final suggestion = currentSuggestions[index];
                            return ActionChip(
                              label: Text(suggestion),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.05,
                              ),
                              labelStyle: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                              elevation: 0,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onPressed: () {
                                setState(() {
                                  _nameController.text = suggestion;

                                  // Auto-fill category if not already selected
                                  if (_selectedCategory == null) {
                                    for (var entry
                                        in widget.suggestedItems.entries) {
                                      if (entry.value.contains(suggestion)) {
                                        _selectedCategory = entry.key;
                                        break;
                                      }
                                    }
                                  }

                                  // جلب آخر سعر تلقائياً
                                  if (_selectedCategory != null) {
                                    final lastPrice = widget.getLastPrice?.call(
                                      suggestion,
                                      _selectedCategory!,
                                    );
                                    if (lastPrice != null && lastPrice > 0) {
                                      _priceController.text = formatCurrency(
                                        lastPrice,
                                      );
                                      _currentPrice = lastPrice;
                                    }
                                  }

                                  // نقل التركيز للسعر مباشرة
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_priceFocusNode);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // 3. السعر والكمية (بتصميم مدمج)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عداد الكمية
                Container(
                  height: 56, // نفس ارتفاع حقل النص
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      _buildQtyBtn(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      _buildQtyBtn(Icons.add, () {
                        setState(() => _quantity++);
                      }),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // حقل السعر
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _priceController,
                        focusNode: _priceFocusNode,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'السعر',
                          suffixText: _selectedCurrency,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // عرض الرصيد المتوفر
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 10),
                        child: Text(
                          'المتوفر: ${formatCurrency(_currentBalance)} $_selectedCurrency',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isOverBudget
                                ? Colors.red
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      // عرض الإجمالي المتوقع تحت الحقل
                      if (_currentPrice > 0 && _quantity > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 10),
                          child: Text(
                            'الإجمالي: ${formatCurrency(_totalEstimated)} $_selectedCurrency',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isOverBudget
                                  ? AppColors.danger
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Dropdown العملة
            Row(
              children: [
                const SizedBox(width: 5),
                const Icon(
                  Icons.currency_exchange_rounded,
                  color: AppColors.textLight,
                  size: 20,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'عملة الشراء',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    items: _currencies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCurrency = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. حقل الملاحظة (اختياري)
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                hintText: 'مثلاً: اسم المحل، تفاصيل المنتج...',
                prefixIcon: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: AppColors.textLight,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // زر الحفظ
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_nameController.text.isNotEmpty &&
                          _selectedCategory != null) {
                        setState(() => _isSaving = true);
                        if (_isOverBudget) {
                          NotificationService().showWarning(
                            context,
                            'تنبيه: هذا العنصر يتجاوز رصيد المحفظة الحالي.',
                          );
                        }

                        try {
                          HapticFeedback.mediumImpact();
                          await widget.onAdd(
                            _nameController.text,
                            _selectedCategory!,
                            _currentPrice,
                            _quantity,
                            _noteController.text,
                            _selectedCurrency,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      } else {
                        NotificationService().showWarning(
                          context,
                          'يرجى اختيار القسم وكتابة اسم المنتج',
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOverBudget
                    ? Colors.grey
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: _isOverBudget ? 0 : 8,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.existingItem != null
                          ? 'حفظ التعديلات'
                          : 'إضافة للقائمة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // زر صغير للكمية
  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
    );
  }
}
