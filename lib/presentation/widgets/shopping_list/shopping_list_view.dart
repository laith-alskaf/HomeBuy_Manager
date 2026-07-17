import 'package:flutter/material.dart';
import 'package:homebuy_manager/data/models/shopping_item.dart';
import 'shopping_list_item.dart';

class ShoppingListView extends StatelessWidget {
  final List<ShoppingItem> items;
  final Map<String, dynamic> categories;
  final Function(String) onDelete;
  final Function(String) onToggle;
  final Function(ShoppingItem) onEdit;

  const ShoppingListView({
    super.key,
    required this.items,
    required this.categories,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      // --- التصحيح هنا ---
      return Center(
        child: SingleChildScrollView( // 1. يسمح بالتمرير إذا ضاقت المساحة
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 2. يأخذ أقل مساحة ممكنة عمودياً
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80, 
                color: Colors.grey.shade300
              ),
              const SizedBox(height: 16),
              Text(
                'القائمة فارغة',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final sortedItems = List<ShoppingItem>.from(items)
      ..sort((a, b) => (a.isBought ? 1 : 0).compareTo(b.isBought ? 1 : 0));

    return ListView.builder(
      // بما أننا نستخدم Expanded في الصفحة الرئيسية، لا نحتاج shrinkWrap هنا
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: sortedItems.length,
      itemBuilder: (ctx, index) {
        final item = sortedItems[index];
        final catData = categories[item.category] ?? categories['other'];

                      return ShoppingListItem( // تم تعديل هذا الجزء لضمان تمرير categoryData
          item: item,
          categoryData: catData,
          onDelete: () => onDelete(item.id),
          onToggle: () => onToggle(item.id),
          onEdit: () => onEdit(item),
        );
      },
    );
  }
}