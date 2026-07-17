import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../data/models/shopping_item.dart';
import '../../services/notification_service.dart';
import '../../utils/formatters.dart';

class CheckoutItemSheet extends StatefulWidget {
  final ShoppingItem item;
  final Map<String, double> balancesByCurrency;
  final Function(String, double, int, String, String) onConfirm;

  const CheckoutItemSheet({
    super.key,
    required this.item,
    required this.balancesByCurrency,
    required this.onConfirm,
  });

  static Future<dynamic> show(
    BuildContext context, {
    required ShoppingItem item,
    required Map<String, double> balancesByCurrency,
    required Function(String, double, int, String, String) onConfirm,
  }) {
    // نستخدم نافذة منسدلة صغيرة تركز على الإدخال المباشر وتغطي فقط النصف السفلي
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CheckoutItemSheet(
          item: item,
          balancesByCurrency: balancesByCurrency,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<CheckoutItemSheet> createState() => _CheckoutItemSheetState();
}

class _CheckoutItemSheetState extends State<CheckoutItemSheet> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();

  int _quantity = 1;
  double _currentPrice = 0.0;
  String _selectedCurrency = 'SYP';
  bool _isSaving = false;
  final List<String> _currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.item.price;
    _priceController.text =
        _currentPrice == 0 ? '' : formatCurrency(_currentPrice);
    _quantity = widget.item.quantity;
    _noteController.text = widget.item.note;
    _selectedCurrency = widget.item.currency;

    _priceController.addListener(() {
      setState(() {
        _currentPrice = parseFormattedNumber(_priceController.text);
      });
    });

    // جلب التركيز تلقائياً لحقل السعر لسرعة إدخاله
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_priceFocusNode);
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  double get _totalEstimated => _currentPrice * _quantity;
  double get _currentBalance =>
      widget.balancesByCurrency[_selectedCurrency] ?? 0.0;
  bool get _isOverBudget => _totalEstimated > _currentBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // مقبض السحب (Handle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // العنوان المميز
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تأكيد الدفع لـ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 1. السعر والكمية
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل السعر (التركيز عليه أوتوماتيكي)
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceController,
                  focusNode: _priceFocusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'سعر الوحدة',
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
              ),
              const SizedBox(width: 12),
              // عداد الكمية
              Expanded(
                flex: 1,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQtyBtn(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      _buildQtyBtn(Icons.add, () {
                        setState(() => _quantity++);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // تفاصيل الإجمالي والميزانية
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 15, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPrice > 0 && _quantity > 1)
                  RichText(
                    text: TextSpan(
                      text: 'الإجمالي: ',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      children: [
                        TextSpan(
                          text:
                              '${formatCurrency(_totalEstimated)} $_selectedCurrency',
                          style: TextStyle(
                            color: _isOverBudget
                                ? AppColors.danger
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  'المتوفر: ${formatCurrency(_currentBalance)} $_selectedCurrency',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOverBudget ? Colors.red : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // 2. Dropdown العملة والملاحظة
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'العملة',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة (في حال الرغبة)',
                    prefixIcon: const Icon(
                      Icons.edit_note,
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
              ),
            ],
          ),

          const SizedBox(height: 25),

          // 3. زر التأكيد السريع
          ElevatedButton.icon(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_currentPrice <= 0) {
                      NotificationService().showWarning(
                        context,
                        'يرجى إدخال سعر صحيح (لا تُقبل الأصفار)',
                      );
                      return;
                    }
                    if (_isOverBudget) {
                      NotificationService().showWarning(
                        context,
                        'تنبيه: المبلغ يتجاوز السقف المتوفر في المحفظة',
                      );
                    }

                    setState(() => _isSaving = true);
                    HapticFeedback.mediumImpact();
                    try {
                      // التنفيذ والإغلاق
                      await widget.onConfirm(
                        widget.item.id,
                        _currentPrice,
                        _quantity,
                        _selectedCurrency,
                        _noteController.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
            icon: const Icon(Icons.check_circle_outline, size: 26),
            label: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'تأكيد الشراء',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isOverBudget ? Colors.grey : AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textDark),
      ),
    );
  }
}
