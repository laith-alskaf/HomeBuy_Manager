import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/app_dimensions.dart';
import '../../../config/app_spacing.dart';

class AppInfoDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<Map<String, dynamic>> features;

  const AppInfoDialog({
    super.key,
    required this.title,
    required this.description,
    required this.features,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    required List<Map<String, dynamic>> features,
  }) {
    showDialog(
      context: context,
      builder: (context) => AppInfoDialog(
        title: title,
        description: description,
        features: features,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس النافذة
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLG),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 28),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: AppTypography.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // المحتوى المنزلق
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textLight,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    
                    // مميزات وفوائد الشاشة
                    if (features.isNotEmpty)
                      ...features.map((feature) => _buildFeatureItem(
                            feature['title'] ?? '',
                            feature['description'] ?? '',
                            feature['icon'] as IconData? ?? Icons.check_circle_rounded,
                            feature['color'] as Color? ?? AppColors.primary,
                          )),
                  ],
                ),
              ),
            ),
            
            // زر الإغلاق
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                  ),
                  child: const Text('فهمت ذلك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String desc, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.body2.copyWith(color: AppColors.textLight, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
