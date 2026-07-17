import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_dimensions.dart';
import '../../../data/models/shopping_item.dart';

class AppDrawer extends StatefulWidget {
  final List<ShoppingItem> items;
  final Map<String, dynamic> categories;
  final VoidCallback onHomeTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onDebtsTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback? onVaultTap;
  final VoidCallback? onSideBalanceTap;
  final VoidCallback? onBillsTap;
  final VoidCallback? onGoalsTap;

  const AppDrawer({
    super.key,
    required this.items,
    required this.categories,
    required this.onHomeTap,
    required this.onDebtsTap,
    required this.onSettingsTap,
    required this.onAnalyticsTap,
    required this.onHistoryTap,
    this.onVaultTap,
    this.onSideBalanceTap,
    this.onBillsTap,
    this.onGoalsTap,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _version = '4.2.0';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusLG),
          bottomLeft: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              children: [
                _DrawerTile(
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onHomeTap();
                  },
                  isActive: true,
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  title: 'أرشيف المشتريات',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onHistoryTap();
                  },
                  isActive: false,
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'الخزنة الذكية',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onVaultTap != null) widget.onVaultTap!();
                  },
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.track_changes_rounded,
                  title: 'حصّالة الأهداف',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onGoalsTap != null) widget.onGoalsTap!();
                  },
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.handshake_rounded,
                  title: 'الديون والمستحقات',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDebtsTap();
                  },
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'الرصيد الجانبي',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onSideBalanceTap != null)
                      widget.onSideBalanceTap!();
                  },
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'الالتزامات الثابتة',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onBillsTap != null) widget.onBillsTap!();
                  },
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.analytics_rounded,
                  title: 'التحليل المالي',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onAnalyticsTap();
                  },
                ),
                const SizedBox(height: 10),
                _DrawerTile(
                  icon: Icons.settings_rounded,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSettingsTap();
                  },
                ),
                const Divider(height: 40),
                _DrawerTile(
                  icon: Icons.share_rounded,
                  title: 'مشاركة التطبيق',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'السلام عليكم، أنصحك بتجربة هذا التطبيق الرائع لإدارة مصاريف المنزل، الديون، والمدخرات بشكل ذكي واحترافي.\n\n'
                      'يمكنك تحميل النسخة من هنا:\n'
                      'https://drive.google.com/drive/folders/1PTTms0S6cwumAz42Ib0R8BlxhqOSv6e1',
                      subject: 'تطبيق ذكي لإدارة المصاريف',
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. تذييل القائمة
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الإصدار $_version',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        60,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/icon/icon.png'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "رادار المصاريف",
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'إدارة ذكية لمصاريفك',
            style: AppTypography.body2.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.textDark,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.body2Medium.copyWith(
            fontWeight: isActive ? AppTypography.bold : AppTypography.medium,
            color: isActive ? AppColors.primary : AppColors.textDark,
          ),
        ),
        trailing: isActive
            ? const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.primary,
              )
            : const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.grey,
              ),
      ),
    );
  }
}
