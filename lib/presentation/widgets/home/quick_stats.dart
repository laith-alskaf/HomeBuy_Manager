import 'package:flutter/material.dart';
import 'package:homebuy_manager/config/app_colors.dart';
import 'package:homebuy_manager/data/models/shopping_item.dart';
import 'package:homebuy_manager/utils/formatters.dart';

class QuickStats extends StatelessWidget {
  final List<ShoppingItem> items;
  final VoidCallback? onPendingTap;

  const QuickStats({super.key, required this.items, this.onPendingTap});

  @override
  Widget build(BuildContext context) {
    // 1. تجهيز البيانات
    final boughtItems = items.where((i) => i.isBought).toList();
    final pendingCount = items.where((i) => !i.isBought).length;

    ShoppingItem? mostExpensive;
    if (boughtItems.isNotEmpty) {
      boughtItems.sort(
        (a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity),
      );
      mostExpensive = boughtItems.first;
    }

    // 2. القائمة الأفقية
    return SizedBox(
      height: 100, // زيادة الارتفاع قليلاً لاستيعاب التصميم الجديد
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // سحب مرن
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // بطاقة: عدد المشتريات (أزرق/تيل)
          _buildStatCard(
            title: 'تم شراؤه',
            value: '${boughtItems.length}',
            unit: 'منتج',
            icon: Icons.check_circle_outline_rounded,
            gradientColors: [AppColors.primary, AppColors.secondary],
          ),

          // بطاقة: أغلى منتج (أحمر/برتقالي)
          if (mostExpensive != null)
            _buildStatCard(
              title: 'أغلى منتج',
              value: formatCompactCurrency(
                mostExpensive.price * mostExpensive.quantity,
              ),
              unit: 'ل.س',
              subtitle: mostExpensive.name,
              icon: Icons.trending_up_rounded,
              gradientColors: [
                const Color(0xFFFF7043),
                const Color(0xFFFFAB91),
              ],
            ),

          // بطاقة: قيد الانتظار (أزرق غامق/نيلي)
          _buildStatCard(
            title: 'قيد الانتظار',
            value: '$pendingCount',
            unit: 'منتج',
            icon: Icons.shopping_cart_outlined,
            gradientColors: [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
            onTap: onPendingTap,
          ),
        ],
      ),
    );
  }

  // ودجت البطاقة المحسنة
  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    String? subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12), // مسافة بين البطاقات
        width: 150, // عرض ثابت ومريح
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. الأيقونة الخلفية الكبيرة (زخرفة)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withOpacity(0.15), // شفافية عالية
              ),
            ),

            // 2. المحتوى النصي
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // العنوان والأيقونة الصغيرة
                  Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // القيمة والوحدة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? unit,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
