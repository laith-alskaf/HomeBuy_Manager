import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../data/models/shopping_item.dart';
import '../widgets/shopping_list/shopping_list_item.dart';
import '../sheets/checkout_item_sheet.dart';

class NeedsListScreen extends StatefulWidget {
  final List<ShoppingItem> items;
  final Map<String, dynamic> categories;
  final Map<String, List<String>> suggestedItems;
  final Future<void> Function(String name, String category) onAddQuick;
  final Map<String, double> balancesByCurrency;
  final Future<void> Function(
    String itemId,
    double price,
    int qty,
    String currency,
    String note,
  )
  onConfirmCheckout;
  final Future<void> Function(ShoppingItem) onEdit;

  const NeedsListScreen({
    super.key,
    required this.items,
    required this.categories,
    required this.suggestedItems,
    required this.onDelete,
    required this.onAddQuick,
    required this.balancesByCurrency,
    required this.onConfirmCheckout,
    required this.onEdit,
  });

  final Function(String id) onDelete;

  @override
  State<NeedsListScreen> createState() => _NeedsListScreenState();
}

class _NeedsListScreenState extends State<NeedsListScreen> {
  final _quickAddController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _selectedCategory;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _quickAddController.addListener(_updateSuggestions);
  }

  void _updateSuggestions() {
    final query = _quickAddController.text.trim().toLowerCase();
    if (query.isEmpty) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }

    List<String> allSuggested = [];
    if (_selectedCategory != null) {
      allSuggested = widget.suggestedItems[_selectedCategory] ?? [];
    } else {
      allSuggested = widget.suggestedItems.values.expand((e) => e).toList();
    }

    final filtered = allSuggested
        .where((item) => item.toLowerCase().contains(query))
        .take(5)
        .toList();

    if (filtered.toString() != _suggestions.toString()) {
      setState(() => _suggestions = filtered);
    }
  }

  @override
  void dispose() {
    _quickAddController.removeListener(_updateSuggestions);
    _quickAddController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectSuggestion(String name) {
    // تحديد القسم تلقائياً إذا أمكن
    String catToUse = _selectedCategory ?? 'other';
    for (var entry in widget.suggestedItems.entries) {
      if (entry.value.any((item) => item.toLowerCase() == name.toLowerCase())) {
        catToUse = entry.key;
        break;
      }
    }

    _quickAddController.text = name;
    setState(() {
      _selectedCategory = catToUse;
      _suggestions = [];
    });
    _focusNode.unfocus();
    _handleAdd();
  }

  void _handleAdd() async {
    final text = _quickAddController.text.trim();
    if (text.isNotEmpty) {
      String catToUse = _selectedCategory ?? 'other'; // افتراضي إذا لم يختر

      // محاولة استنتاج القسم من المقترحات إذا لم يحدده
      if (_selectedCategory == null) {
        for (var entry in widget.suggestedItems.entries) {
          if (entry.value.any(
            (item) => item.toLowerCase() == text.toLowerCase(),
          )) {
            catToUse = entry.key;
            break;
          }
        }
      }

      await widget.onAddQuick(text, catToUse);
      _quickAddController.clear();

      if (mounted) {
        setState(() {
          _selectedCategory = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // نجلب فقط العناصر غير المشتراة
    final pendingItems = widget.items.where((i) => !i.isBought).toList();
    pendingItems.sort((a, b) => b.id.compareTo(a.id)); // الأحدث أولاً

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'المشتريات المعلقة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          // شريط الإضافة السريعة (Quick Add)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                // زر اختيار القسم السريع
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Icon(
                      Icons.category_rounded,
                      color: Colors.grey,
                    ),
                    icon:
                        const SizedBox.shrink(), // إخفاء سهم الدروب داون لتوفير المساحة
                    items: widget.categories.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Icon(
                          e.value['icon'],
                          color: e.value['color'],
                          size: 24,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _quickAddController,
                        focusNode: _focusNode,
                        onSubmitted: (_) => _handleAdd(),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'ماذا تنوي أن تشتري؟',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _handleAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // قائمة الاقتراحات المنبثقة
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(s, style: const TextStyle(fontSize: 13)),
                    onTap: () => _selectSuggestion(s),
                    trailing: const Icon(
                      Icons.arrow_right_alt_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

          // القائمة
          Expanded(
            child: pendingItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا يوجد نواقص حالياً!',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اكتب ما تحتاجه في الأعلى',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingItems.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = pendingItems[index];
                      final catData =
                          widget.categories[item.category] ??
                          widget.categories['other'];

                      return ShoppingListItem(
                        item: item,
                        categoryData: catData,
                        onDelete: () {
                          widget.onDelete(item.id);
                          setState(() {}); // تحديث فوري للقائمة
                        },
                        onToggle: () {
                          // عند الضغط على تأكيد الشراء، نظهر نافذة الدفع
                          CheckoutItemSheet.show(
                            context,
                            item: item,
                            balancesByCurrency: widget.balancesByCurrency,
                            onConfirm:
                                (itemId, price, qty, currency, note) async {
                                  await widget.onConfirmCheckout(
                                    itemId,
                                    price,
                                    qty,
                                    currency,
                                    note,
                                  );
                                  if (mounted) {
                                    setState(
                                      () {},
                                    ); // تحديث فوري لإخفاء العنصر بعد الشراء
                                  }
                                },
                          );
                        },
                        onEdit: () {
                          widget.onEdit(item).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
