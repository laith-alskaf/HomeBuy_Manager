import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../dialogs/budget_setup_dialog.dart';
import '../dialogs/update_dialog.dart';
import '../pages/about_screen.dart';
import '../../data/models/shopping_item.dart';
import 'backup_screen.dart';
import '../../services/remote_config_service.dart';
import '../../services/notification_service.dart';
import '../../services/firebase_notification_service.dart';

class SettingsPage extends StatefulWidget {
  final double currentThreshold;
  final Map<String, double> currentSpending;
  final List<ShoppingItem> allItems;
  final double currentBalance;
  final String currentUserName;

  const SettingsPage({
    super.key,
    required this.currentThreshold,
    required this.currentSpending,
    required this.allItems,
    required this.currentBalance,
    required this.currentUserName,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _thresholdController;
  late TextEditingController _nameController;
  bool _isLoading = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(
      text: widget.currentThreshold.toStringAsFixed(0),
    );
    _nameController = TextEditingController(text: widget.currentUserName);
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // محاكاة للواقعية

    final prefs = await SharedPreferences.getInstance();
    final newLimit = double.tryParse(_thresholdController.text) ?? 50000;
    final newName = _nameController.text.trim();
    await prefs.setDouble('low_balance_threshold', newLimit);
    await prefs.setString('user_name', newName);

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('تم حفظ الإعدادات بنجاح'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      Navigator.pop(context, newLimit);
    }
  }

  Future<void> _startNewFinancialCycle() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد بدء شهر جديد'),
        content: const Text(
          'هل أنت متأكد أنك تريد إنهاء الدورة المالية الحالية والبدء بدورة جديدة؟ سيتم ترحيل مدخراتك السابقة كـ "رصيد مدور".',
          style: TextStyle(height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'نعم، متأكد',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cycle_start_date',
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('تم بدء شهر مالي جديد بنجاح!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isLoading = true);
    final remoteConfig = RemoteConfigService();

    // Use force fetch to bypass cache interval
    final errorMessage = await remoteConfig.forceFetchAndActivate();

    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMessage == null) {
        final latestVersion = remoteConfig.latestAppVersion;

        if (_isUpdateAvailable(_appVersion, latestVersion)) {
          // Show Professional Update Dialog
          final isForced = remoteConfig.forceUpdate;
          showDialog(
            context: context,
            barrierDismissible: !isForced,
            builder: (context) => UpdateDialog(
              version: latestVersion,
              downloadUrl: FirebaseNotificationService.updateUrl,
              isForceUpdate: isForced,
              newFeatures: remoteConfig.newFeatures,
            ),
          );
        } else {
          NotificationService().showInfo(
            context,
            'أنت تستخدم أحدث إصدار من التطبيق ($_appVersion).',
          );
        }
      } else {
        // Show the actual error to help diagnosis
        NotificationService().showError(context, errorMessage);
      }
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    try {
      // Clean versions from build numbers (e.g., 1.0.0+1 -> 1.0.0)
      final cleanCurrent = current.split('+')[0];
      final cleanLatest = latest.split('+')[0];

      List<int> currentParts = cleanCurrent.split('.').map(int.parse).toList();
      List<int> latestParts = cleanLatest.split('.').map(int.parse).toList();

      int length = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;

      for (int i = 0; i < length; i++) {
        int v1 = i < currentParts.length ? currentParts[i] : 0;
        int v2 = i < latestParts.length ? latestParts[i] : 0;
        if (v2 > v1) return true;
        if (v2 < v1) return false;
      }
      return false;
    } catch (e) {
      return latest != current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: AppTypography.h5.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- المجموعة الأولى: حسابك الشخصي ---
          _buildGroupHeader('حسابك الشخصي'),
          _buildPersonalSection(),
          const SizedBox(height: 25),

          // --- المجموعة الثانية: الإدارة المالية ---
          _buildGroupHeader('الإدارة المالية'),
          _buildFinancialSection(),
          const SizedBox(height: 25),

          // --- المجموعة الثالثة: البيانات والأمان ---
          _buildGroupHeader('البيانات والارتباط'),
          _buildDataSection(),
          const SizedBox(height: 25),

          // --- المجموعة الرابعة: حول التطبيق ---
          _buildGroupHeader('حول التطبيق والتحديثات'),
          _buildAboutSection(),

          // --- التذييل: رقم الإصدار ---
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  'رادار المصروف',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الإصدار $_appVersion',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _buildCard([
      TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'الاسم الكامل',
          hintText: 'أدخل اسمك هنا',
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            color: Colors.grey,
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    ]);
  }

  Widget _buildFinancialSection() {
    return _buildCard([
      // حد الرصيد
      Row(
        children: [
          _buildIconBox(Icons.notifications_active_rounded, Colors.orange),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حد الرصيد المنخفض',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'تنبيه عند انخفاض الرصيد',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      TextField(
        controller: _thresholdController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'قيمة الحد الأدنى (ل.س)',
          suffixText: 'ل.س',
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 20),
      // زر الحفظ
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'حفظ الإعدادات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
      const Divider(height: 35),
      // ميزانية الفئات
      _buildListTile(
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.purple,
        title: 'ميزانية الفئات',
        subtitle: 'تعيين حدود لكل فئة',
        onTap: () => showDialog(
          context: context,
          builder: (context) => BudgetSetupDialog(
            currentSpending: widget.currentSpending,
            allItems: widget.allItems,
            totalWalletBalance: widget.currentBalance,
          ),
        ),
      ),
      const Divider(height: 35),
      // تدوير الشهر
      _buildListTile(
        icon: Icons.event_repeat_rounded,
        color: Colors.amber,
        title: 'بدء شهر جديد',
        subtitle: 'تصفير المصاريف وترحيل الرصيد',
        onTap: _isLoading ? null : _startNewFinancialCycle,
      ),
    ]);
  }

  Widget _buildDataSection() {
    return _buildCard([
      _buildListTile(
        icon: Icons.backup_rounded,
        color: Colors.blue,
        title: 'النسخ الاحتياطي',
        subtitle: 'حفظ واستعادة بياناتك',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BackupScreen()),
        ),
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildCard([
      _buildListTile(
        icon: Icons.system_update_rounded,
        color: Colors.green,
        title: 'البحث عن تحديثات',
        subtitle: 'التأكد من توفر إصدار أحدث',
        trailing: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _isLoading ? null : _checkForUpdates,
      ),
      const Divider(height: 30),
      _buildListTile(
        icon: Icons.info_outline_rounded,
        color: AppColors.primary,
        title: 'حول التطبيق',
        subtitle: 'معلومات المطور والترخيص',
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          _buildIconBox(icon, color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey,
              ),
        ],
      ),
    );
  }
}
