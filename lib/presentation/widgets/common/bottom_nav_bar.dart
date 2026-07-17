import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/app_dimensions.dart';
import '../../../config/app_spacing.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      height: 75,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: AppColors.mediumShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            index: 0,
            icon: Icons.dashboard_rounded,
            label: 'الرئيسية',
            isSelected: currentIndex == 0,
            onTap: () => onIndexChanged(0),
          ),

          const SizedBox(width: 40), // مسافة لزر الـ FAB

          _NavBarItem(
            index: 1,
            icon: Icons.pie_chart_rounded,
            label: 'إحصائيات',
            isSelected: currentIndex == 1,
            onTap: () => onIndexChanged(1),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. أنيميشن الأيقونة
            AnimatedContainer(
              duration: Duration(milliseconds: AppDimensions.durationNormal),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: isSelected ? 28 : 26,
              ),
            ),

            // 2. أنيميشن النص
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: AppDimensions.durationFast),
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textLight,
                fontWeight:
                    isSelected ? AppTypography.semiBold : AppTypography.regular,
              ),
              child: Text(label),
            ),

            const SizedBox(height: 4),

            // 3. النقطة السفلية (أنيميشن Scale)
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: Duration(milliseconds: AppDimensions.durationNormal),
              curve: Curves.elasticOut,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
